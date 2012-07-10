class Location < ActiveRecord::Base
  belongs_to :region
  geocoded_by :address, :latitude => :lat, :longitude => :lng   # can also be an IP address
  after_validation :geocode    
  attr_accessible :address, :admin_notes, :contact, :donor_type, :hours, :is_donor, :lat, :lng, :name, :public_notes, :recip_category, :website

  # CRUD-level restrictions
  def authorized_for_update?
    current_user.admin or current_user.region_admin?(self.region)
  end
  def authorized_for_create?
    current_user.admin or current_user.region_admin?(self.region)
  end
  def authorized_for_delete?
    current_user.admin or current_user.region_admin?(self.region)
  end
end
