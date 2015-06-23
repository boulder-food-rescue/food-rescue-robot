class Volunteer < ActiveRecord::Base
  belongs_to :transport_type
  belongs_to :cell_carrier
  has_many :assignments
  has_many :absences
  has_many :regions, :through => :assignments
  belongs_to :requested_region, :class_name => "Region"
  attr_accessible :pre_reminders_too, :region_ids, :password, :password_confirmation, 
    :remember_me, :admin_notes, :email, :has_car, :is_disabled, :name,
    :on_email_list, :phone, :pickup_prefs, :preferred_contact, :transport, :sms_too, 
    :transport_type, :cell_carrier, :cell_carrier_id, :transport_type_id, :photo, :get_sncs_email, 
    :assigned, :requested_region_id, :authentication_token
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_attached_file :photo, :styles => { :thumb => "50x50", :small => "200x200", :medium => "500x500" }
  default_scope { order('volunteers.name ASC').where(active:true) }

  has_many :schedule_volunteers
  has_many :schedule_chains, :through=>:schedule_volunteers, 
           :conditions=>{"schedule_volunteers.active"=>true}
  has_many :prior_schedules, :through=>:schedule_volunteers, 
           :conditions=>{"schedule_volunteers.active"=>false}, :class_name=>"ScheduleChain"

  has_many :log_volunteers
  has_many :logs, :through=>:log_volunteers,
           :conditions=>{"log_volunteers.active"=>true}
  has_many :prior_logs, :through=>:log_volunteers,
           :conditions=>{"log_volunteers.active"=>false}, :class_name=>"Log"

  before_save :ensure_authentication_token
  after_save :auto_assign_region

  # more trustworthy and self.assigned? attribute?
  def unassigned?
    self.assignments.length == 0
  end

  def needs_training?
    not self.logs.collect{ |l| l.complete }.any?
  end

  # devise overrides to deal with not approved stuff
  # https://github.com/plataformatec/devise/wiki/How-To:-Require-admin-to-activate-account-before-sign_in
  def active_for_authentication?
    super && assigned?
  end

  def inactive_message
    if not assigned
      :not_assigned
    else
      super
    end
  end

  def self.send_reset_password_instructions(attributes={})
    recoverable = find_or_initialize_with_errors(reset_password_keys, attributes, :not_found)
    if !recoverable.assigned?
      recoverable.errors[:base] << I18n.t("devise.failure.not_approved")
    elsif recoverable.persisted?
      recoverable.send_reset_password_instructions
    end
    recoverable
  end

  def sms_email
    return nil if self.cell_carrier.nil? or self.phone.nil? or self.phone.strip == ""
    return nil unless self.phone.tr('^0-9','') =~ /^(\d{10})$/
    # a little scary that we're blindly assuming the format is reasonable, but only admin can edit it...
    return sprintf(self.cell_carrier.format,$1)
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
      self.save
    end
  end

  def reset_authentication_token
    self.authentication_token = generate_authentication_token
    self.save
  end

  ### REGION-RELATED METHODS

  # Admin info accessors
  def super_admin?
    self.admin
  end

  # if first argument is nil, checks if they're a region admin
  # of any kind. otherwise, tests if they're a admin for the given region
  # if strict is false, will not return true if they're a super admin
  def region_admin?(r=nil,strict=true)
    return true if not strict and self.super_admin?
    a = self.admin_region_ids(strict)
    if r.nil?
      return true unless a.empty?
    else
      return true if a.include? r.id
    end
    return false
  end

  # non-strict version of the above
  def any_admin?(region=nil)
    self.region_admin?(region,false)
  end

  def has_main_region?
    !main_region.nil?
  end

  def main_region
    self.regions[0]
  end

  def region_ids
    self.regions.collect{ |r| r.id }
  end

  def admin_region_ids(strict=false)
    admin_regions(strict).collect { |r| r.id }
  end

  def admin_regions(strict=false)
    if self.super_admin? and not strict
      Region.all
    else
      self.assignments.collect{ |a| a.admin ? a.region : nil }.compact
    end
  end

  def in_region? region_id
    self.region_ids.include? region_id
  end

  # better first-time experience: if there is only one region, add the user to that one automatically when they sign up
  def auto_assign_region
    if Region.count==1 and self.regions.count==0
      Assignment.add_volunteer_to_region self, Region.first
      logger.info "Automatically assigned new user to region #{self.regions.first.name}"
    end
  end

  def current_absences
    self.absences.keep_if{ |a| a.start_date < Date.today and a.stop_date > Date.today }
  end

  ### CLASS METHODS

  def self.active(region_ids=nil,ndays=90)
    Volunteer.joins(:logs).select("max(logs.when) as last_log_date,volunteers.*").
      group("volunteers.id").keep_if{ |v|
        (Date.parse(v.last_log_date) > Time.zone.today-ndays) and (region_ids.nil? or (v.region_ids & region_ids).length > 0)
      }
  end

  def self.all_for_region region_id
    self.includes(:regions).where(:regions=>{:id=>region_id}).compact
  end


  private

  def generate_authentication_token
    loop do
      token = Devise.friendly_token
      break token unless Volunteer.where(authentication_token: token).first
    end
  end

end