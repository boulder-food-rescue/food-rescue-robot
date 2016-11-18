class Region < ActiveRecord::Base
  has_many :assignments
  has_many :volunteers, through: :assignments
  has_many :food_types
  has_many :scale_types
  has_many :schedule_chains
  has_many :locations
  has_many :logs
  has_many :donors
  has_many :recipients

  scope :all_admin, ->(volunteer) { where(id: volunteer.admin_region_ids) }

  geocoded_by :address, latitude:  :lat, longitude:  :lng # can also be an IP address
  after_validation :geocode

  attr_accessible :address, :lat, :lng, :name, :notes, :website, :handbook_url, :welcome_email_text,
                  :splash_html, :title, :tagline,
                  :phone, :tax_id, :twitter_key, :twitter_secret, :twitter_token,
                  :twitter_token_secret, :weight_unit, :time_zone, :logo, :post_pickup_emails,
                  :unschedule_self, :volunteer_coordinator_email

  has_attached_file :logo,
                    styles: { thumb: '50x50' },
                    s3_credentials: { bucket: 'boulder-food-rescue-robot-region-photo' }
  validates_attachment_file_name :logo, matches: [/png\Z/, /jpe?g\Z/, /gif\Z/]

  def self.has_any_handbooks?(region_list)
    region_list.any?(&:has_handbook?)
  end

  def active_volunteer_count
   schedule_chains.flat_map(&:volunteers).uniq.count
  end

  def has_sellers?
    locations.any? do |location|
      location.location_type == Location::LocationType.invert["Seller"]
    end
  end

  def has_buyers?
    locations.any? do |location|
      location.location_type == Location::LocationType.invert["Buyer"]
    end
  end

  def has_hubs?
    locations.any? do |location|
      location.location_type == Location::LocationType.invert["Hub"]
    end
  end

  def has_handbook?
    handbook_url.present?
  end
end
