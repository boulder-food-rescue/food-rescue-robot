class Volunteer < ActiveRecord::Base
  belongs_to :transport_type
  belongs_to :cell_carrier
  has_many :assignments
  has_many :regions, :through => :assignments

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :trackable, :validatable

  has_attached_file :photo, :styles => { :thumb => "50x50", :small => "200x200", :medium => "500x500" }

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
  def any_admin?
    self.super_admin? or self.region_admin?
  end

  def sms_email
    return nil if self.cell_carrier.nil? or self.phone.nil? or self.phone.strip == ""
    return nil unless self.phone.tr('^0-9','') =~ /^(\d{10})$/
    # a little scary that we're blindly assuming the format is reasonable, but only admin can edit it...
    return sprintf(self.cell_carrier.format,$1) 
  end 

  def main_region
    self.regions[0]
  end
  def region_ids
    self.regions.collect{ |r| r.id }
  end
  def admin_region_ids
    self.assignments.collect{ |a| a.admin ? a.region.id : nil }.compact
  end

  def gone?
    !self.gone_until.nil? and self.gone_until > Date.today
  end

  def self.all_for_region region_id
    self.includes(:regions).where(:regions=>{:id=>region_id}).compact
  end

  # Setup accessible (or protected) attributes for your model
  attr_accessible :pre_reminders_too, :region_ids, :password, :password_confirmation, :remember_me, :admin_notes, :email, :gone_until, :has_car, :is_disabled, :name, :on_email_list, :phone, :pickup_prefs, :preferred_contact, :transport, :sms_too, :transport_type, :cell_carrier, :cell_carrier_id, :transport_type_id, :photo, :get_sncs_email, :needs_training
end
