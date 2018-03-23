# Volunteer is the god object for BFR Robot
class Volunteer < ActiveRecord::Base
  default_scope { order('volunteers.name ASC').where(active: true) }

  belongs_to :transport_type
  belongs_to :cell_carrier
  belongs_to :requested_region, class_name: 'Region'

  has_many :absences

  has_many :assignments
  has_many :regions, through: :assignments

  has_many :schedule_volunteers
  has_many :schedule_chains, through: :schedule_volunteers,
           conditions: { 'schedule_volunteers.active' => true }
  has_many :prior_schedules, through: :schedule_volunteers,
           conditions: { 'schedule_volunteers.active' => false },
           class_name: 'ScheduleChain'

  has_many :log_volunteers
  has_many :logs, through: :log_volunteers,
           conditions: { 'log_volunteers.active' => true }
  has_many :prior_logs, through: :log_volunteers,
           conditions: { 'log_volunteers.active' => false },
           class_name: 'Log'

  attr_accessible :pre_reminders_too, :region_ids, :password,
                  :password_confirmation, :remember_me, :admin_notes, :email,
                  :has_car, :is_disabled, :name, :on_email_list, :phone,
                  :pickup_prefs, :preferred_contact, :transport, :sms_too,
                  :transport_type, :cell_carrier, :cell_carrier_id,
                  :transport_type_id, :photo, :get_sncs_email,
                  :assigned, :requested_region_id, :authentication_token

  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_attached_file :photo,
                    styles: { thumb: '50x50', small: '200x200', medium: '500x500' },
                    s3_credentials: { bucket: 'boulder-food-rescue-robot-volunteer-photo' }
  validates_attachment_file_name :photo, matches: [/png\Z/, /jpe?g\Z/, /gif\Z/]

  before_save :ensure_authentication_token
  after_save :auto_assign_region

  # more trustworthy and self.assigned? attribute?
  def unassigned?
    assignments.empty?
  end

  def needs_training?
    logs.where(complete: true).count.zero?
  end

  # devise overrides to deal with not approved stuff
  # https://github.com/plataformatec/devise/wiki/How-To:-Require-admin-to-activate-account-before-sign_in
  def active_for_authentication?
    super && assigned?
  end

  def inactive_message
    if assigned?
      super
    else
      :not_assigned
    end
  end

  def self.send_reset_password_instructions(attributes = {})
    recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
    if !recoverable.assigned?
      recoverable.errors[:base] << I18n.t('devise.failure.not_approved')
    elsif recoverable.persisted?
      recoverable.send_reset_password_instructions
    end
    recoverable
  end

  def sms_email
    return nil if cell_carrier.nil? || phone.nil? || phone.strip == ''
    return nil unless phone.tr('^0-9', '') =~ /^(\d{10})$/
    # a little scary that we're blindly assuming the format is reasonable, but only admin can edit it...
    sprintf(cell_carrier.format, $1)
  end

  def ensure_authentication_token
    return unless authentication_token.blank?

    self.authentication_token = generate_authentication_token
    save
  end

  def reset_authentication_token
    self.authentication_token = generate_authentication_token
    save
  end

  ### REGION-RELATED METHODS

  # Admin info accessors
  def super_admin?
    admin
  end

  # if first argument is nil, checks if they're a region admin
  # of any kind. otherwise, tests if they're a admin for the given region
  # if strict is false, will not return true if they're a super admin
  def region_admin?(region = nil, strict = true)
    return true if !strict && super_admin?

    admin_regions_ids = admin_region_ids(strict)

    if region.nil?
      return true unless admin_regions_ids.empty?
    elsif admin_regions_ids.include?(region.id)
      return true
    end

    false
  end

  # non-strict version of the above
  def any_admin?(region = nil)
    region_admin?(region, false)
  end

  def has_main_region?
    !main_region.nil?
  end

  def main_region
    regions.first
  end

  def admin_region_ids(strict = false)
    admin_regions(strict).collect(&:id)
  end

  def admin_regions(strict = false)
    if super_admin? && !strict
      Region.all
    else
      assignments
        .eager_load(:region)
        .where(admin: true)
        .collect(&:region)
        .compact
    end
  end

  def in_region?(region_id)
    region_ids.include? region_id
  end

  def current_absences
    today = Date.today

    absences.where('start_date < ? AND stop_date > ?', today, today)
  end

  ### CLASS METHODS

  def self.active(region_ids = nil, ndays = 90)
    query = joins(:logs).group('volunteers.id').having('max(logs.when) > ?', Time.zone.today - ndays)

    if region_ids.present?
      query.joins(:regions).where(regions: { id: region_ids })
    else
      query
    end
  end

  def self.inactive(region_ids = nil)
    query = where(active: false)

    if region_ids.present?
      query.joins(:regions).where(regions: { id: region_ids }).group('volunteers.id')
    else
      query
    end
  end

  def self.all_for_region(region_id)
    includes(:regions).
      where(regions: { id: region_id }).
      compact
  end

  def self.active_but_shiftless(region_ids)
    includes(:regions)
      .where(regions: { id: region_ids })
      .where('regions.id' => region_ids)
      .where('(SELECT COUNT(*) FROM schedule_chains ' \
            'INNER JOIN schedule_volunteers ON ' \
            'schedule_chains.id = schedule_volunteers.schedule_chain_id ' \
            "WHERE schedule_chains.active = 't' " \
            'AND schedule_volunteers.volunteer_id = volunteers.id ' \
            "AND schedule_volunteers.active = 't') = 0")
  end

  private

  # better first-time experience: if there is only one region, add the user to
  # that one automatically when they sign up
  def auto_assign_region
    if Region.count == 1 && regions.count.zero?
      Assignment.add_volunteer_to_region self, Region.first
      logger.info "Automatically assigned new user to region #{regions.first.name}"
    end
  end

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless Volunteer.where(authentication_token: token).first
    end
  end
end
