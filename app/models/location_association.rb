class LocationAssociation < ActiveRecord::Base
  belongs_to :location_admin
  belongs_to :location
  attr_accessible :admin, :location_admin_id, :location_id

end
