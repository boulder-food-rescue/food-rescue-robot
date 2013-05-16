class Region < ActiveRecord::Base
  has_many :assignments
  has_many :volunteers, :through => :assignments
  has_many :food_types
  geocoded_by :address, :latitude => :lat, :longitude => :lng   # can also be an IP address
  after_validation :geocode
  attr_accessible :address, :lat, :lng, :name, :notes, :website, :handbook_url, :welcome_email_text, :splash_html
  has_attached_file :logo, :styles => { :thumb => "50x50" }

  def self.all_admin(volunteer)
    Region.where("id IN (#{volunteer.admin_region_ids.join(",")})")
  end

  # ActiveScaffold CRUD-level restrictions
  def authorized_for_update?
    current_user.super_admin?
  end
  def authorized_for_create?
    current_user.super_admin?
  end
  def authorized_for_delete?
    current_user.super_admin?
  end

end
