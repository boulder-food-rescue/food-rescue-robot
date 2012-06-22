class Location < ActiveRecord::Base
  attr_accessible :address, :admin_notes, :contact, :donor_type, :hours, :is_donor, :lat, :lng, :name, :public_notes, :recip_category, :website
end
