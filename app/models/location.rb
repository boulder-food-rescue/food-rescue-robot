class Location < ActiveRecord::Base
  belongs_to :region
  geocoded_by :address, :latitude => :lat, :longitude => :lng   # can also be an IP address
  after_validation :geocode    
  attr_accessible :region_id, :address, :twitter_handle, :admin_notes, :contact, :donor_type, :hours, :is_donor, :lat, :lng, :name, :public_notes, :recip_category, :website

  def json
    ret = <<EOF
'[{"description": "#{self.contact}", "title": "#{self.name}", "sidebar": "", "lng": "#{self.longitude}", "lat": "#{self.latitude}", "picture": "", "width": "", "height": ""},{"lng": "#{self.longitude}", "lat": "#{self.latitude}" }]'
EOF
  end
end
