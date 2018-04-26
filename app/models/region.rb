class Region < ActiveRecord::Base
  has_many :assignments
  has_many :volunteers, through: :assignments
  has_many :food_types
  has_many :scale_types
  has_many :schedule_chains
  has_many :locations
  has_many :logs

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

  def self.any_handbooks?(region_list)
    region_list.any?(&:handbook?)
  end

  def active_volunteer_count
    schedule_chains.flat_map(&:volunteers).uniq.count
  end

  def sellers?
    locations.where(location_type: Location::LOCATION_TYPES.invert['Seller']).any?
  end

  def buyers?
    locations.where(location_type: Location::LOCATION_TYPES.invert['Buyer']).any?
  end

  def hubs?
    locations.where(location_type: Location::LOCATION_TYPES.invert['Hub']).any?
  end

  def handbook?
    handbook_url.present?
  end
end
