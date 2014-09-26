class Region < ActiveRecord::Base
  has_many :assignments
  has_many :volunteers, :through => :assignments
  has_many :food_types
  has_many :scale_types
  has_many :schedules
	has_many :locations
  has_many :logs

  has_many :donors
  has_many :recipients

  geocoded_by :address, :latitude => :lat, :longitude => :lng   # can also be an IP address
  after_validation :geocode
  attr_accessible :address, :lat, :lng, :name, :notes, :website, :handbook_url, :welcome_email_text, :splash_html, :title, :tagline, 
                  :phone, :tax_id, :twitter_key, :twitter_secret, :twitter_token, :twitter_token_secret, :weight_unit, :time_zone, :logo
  has_attached_file :logo, :styles => { :thumb => "50x50" }

  def active_volunteer_count
    volunteers = self.schedules.collect_concat {|schedule| schedule.volunteers }
    volunteers.uniq.count
  end

  def self.all_admin volunteer
    Region.where(:id=>volunteer.admin_region_ids)
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
