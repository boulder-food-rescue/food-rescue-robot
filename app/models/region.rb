class Region < ActiveRecord::Base
  geocoded_by :address, :latitude => :lat, :longitude => :lng   # can also be an IP address
  after_validation :geocode
  attr_accessible :address, :lat, :lng, :name, :notes, :website
end
