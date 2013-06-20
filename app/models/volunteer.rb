class Volunteer < ActiveRecord::Base
  belongs_to :transport_type
  belongs_to :cell_carrier
  has_many :assignments
  has_many :regions, :through => :assignments
  belongs_to :requested_region, :class_name => "Region"
  attr_accessible :pre_reminders_too, :region_ids, :password, :password_confirmation, 
    :remember_me, :admin_notes, :email, :gone_until, :has_car, :is_disabled, :name, 
    :on_email_list, :phone, :pickup_prefs, :preferred_contact, :transport, :sms_too, 
    :transport_type, :cell_carrier, :cell_carrier_id, :transport_type_id, :photo, :get_sncs_email, 
    :needs_training, :assigned, :requested_region_id
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable
  has_attached_file :photo, :styles => { :thumb => "50x50", :small => "200x200", :medium => "500x500" }

  after_save :auto_assign_region

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

  # Admin info accessors
  def super_admin?
    self.admin
  end
  def region_admin?(r=nil)
    self.assignments.each{ |a|
      return true if (a.admin and r.nil?) or (a.admin and r == a.region)
    }
    return false
  end
  def any_admin? region=nil
    self.super_admin? or self.region_admin? region
  end

  def sms_email
    return nil if self.cell_carrier.nil? or self.phone.nil? or self.phone.strip == ""
    return nil unless self.phone.tr('^0-9','') =~ /^(\d{10})$/
    # a little scary that we're blindly assuming the format is reasonable, but only admin can edit it...
    return sprintf(self.cell_carrier.format,$1) 
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
  def admin_region_ids
    if self.super_admin?
      Region.all.collect{ |r| r.id }
    else
      self.assignments.collect{ |a| a.admin ? a.region.id : nil }.compact
    end
  end

  def gone?
    !self.gone_until.nil? and self.gone_until > Date.today
  end

  def self.all_for_region region_id
    self.includes(:regions).where(:regions=>{:id=>region_id}).compact
  end

  # better first-time experience: if there is only one region, add the user to that one automatically when they sign up
  def auto_assign_region
    if Region.count==1 and self.regions.count==0
      Assignment.add_volunteer_to_region self, Region.first
      logger.info "Automatically assigned new user to region #{self.regions.first.name}"
    end
  end

end
