class Region < ActiveRecord::Base
  has_many :assignments
  has_many :volunteers, :through => :assignments
  has_many :food_types
  geocoded_by :address, :latitude => :lat, :longitude => :lng   # can also be an IP address
  after_validation :geocode
  attr_accessible :address, :lat, :lng, :name, :notes, :website, :handbook_url, :welcome_email_text, :splash_html
  has_attached_file :logo, :styles => { :thumb => "50x50" }

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

  def has_handbook?
    not handbook_url.nil?
  end

  def self.has_any_handbooks? region_list
    handbook_count = 0
    # for some reason I couldn't get .count to work here :-(
    region_list.each { |r| handbook_count+= 1 if r.has_handbook? }
    handbook_count > 0 
  end

end
