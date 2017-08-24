class Location < ActiveRecord::Base

  # MOVE TO ENUM
  LOCATION_TYPES = {
    0 => 'Recipient',
    1 => 'Donor',
    2 => 'Hub',
    3 => 'Seller',
    4 => 'Buyer'
  }

  PICKUP_LOCATION_TYPES = [1, 2, 3]
  DROP_LOCATION_TYPES   = [0, 2, 4]

  belongs_to :region
  has_many :log_recipients

  geocoded_by :address, latitude: :lat, longitude: :lng   # can also be an IP address
  acts_as_gmappable process_geocoding: false, lat: 'lat', lng: 'lng', address: 'address'

  after_initialize :init_detailed_hours_json
  before_save :populate_detailed_hours_json_before_save
  before_save :populate_receipt_key
  after_validation :geocode
  validate :detailed_hours_cannot_end_before_start

  default_scope { order('locations.name ASC').where(active: true) }
  scope :regional,   -> (ids) { where(region_id: ids) }
  scope :active,     -> { where(active: true) }
  scope :recipients, -> { where(location_type: LOCATION_TYPES.invert['Recipient']) }
  scope :donors,     -> { where(location_type: LOCATION_TYPES.invert['Donor']) }
  scope :hubs,       -> { where(location_type: LOCATION_TYPES.invert['Hub']) }
  scope :sellers,    -> { where(location_type: LOCATION_TYPES.invert['Seller']) }
  scope :buyers,     -> { where(location_type: LOCATION_TYPES.invert['Buyer']) }

  attr_accessible :region_id, :address, :twitter_handle, :admin_notes, :contact, :donor_type, :hours,
                  :lat, :lng, :name, :public_notes, :recip_category, :website, :receipt_key,
                  :email, :phone, :equipment_storage_info, :food_storage_info, :entry_info, :exit_info,
                  :onsite_contact_info, :active, :location_type

  def is_donor
    location_type == LOCATION_TYPES.invert['Donor']
  end
  alias donor? is_donor

  def is_hub
    location_type == LOCATION_TYPES.invert['Hub']
  end
  alias hub? is_hub

  def gmaps4rails_title
    self.name
  end

  def gmaps4rails_infowindow
    ret = "<span style=\"font-weight: bold;color: darkblue;\">#{self.name}</span><br>"
    ret += self.address.gsub("\n", '<br>') unless self.address.nil?
    ret += '<br>'
    ret += self.contact.gsub("\n", '<br>') unless self.contact.nil?
    ret += '<br>'
    ret += self.hours.gsub("\n", '<br>') unless self.hours.nil?
    ret += '<br>'
    ret += "<a href=\"#{self.website}\">website</a>" unless self.website.nil?
    ret
  end

  def gmaps4rails_marker_picture
    {
      'picture' => self.is_donor ? 'http://maps.gstatic.com/intl/en_ALL/mapfiles/dd-start.png' :
                                   'http://maps.gstatic.com/intl/en_ALL/mapfiles/dd-end.png'          # string,  mandatory
    }
  end

  # this has to be smart about time zones
  def open?(time = nil)
    time = Time.new if time.nil?
    time = time.in_time_zone(self.time_zone)
    day_index = time.wday
    return unless open_on_day? day_index
    hours = hours_on_day day_index
    (time > hours[0]) && (time < hours[1])
  end

  def hours_on_day(index)
    [ read_day_info('day'+index.to_s+'_start') , read_day_info('day'+index.to_s+'_end') ]
  end

  def open_on_day?(index)
    read_day_info('day'+index.to_s+'_status') == 1
  end

  def populate_detailed_hours_from_form(params)
    detailed_hours = day_info

    (0..6).each do |index|
      prefix = "day#{index}"
      original_day_info["#{prefix}_status"] = params[prefix]['status'].to_i
      original_day_info["#{prefix}_start"] = Time.find_zone(time_zone).parse("#{params[prefix]['start']['hour']}:#{params[prefix]['start']['minute']}")
      original_day_info["#{prefix}_end"] = Time.find_zone(time_zone).parse("#{params[prefix]['end']['hour']}:#{params[prefix]['end']['minute']}")
    end

    self.detailed_hours_json = detailed_hours.to_json

    populate_detailed_hours_json_before_save
  end

  # normalized website url
  def website_url
    return nil if self.website.blank?
    uri = Addressable::URI.parse(self.website)
    uri = Addressable::URI.parse("http://#{self.website.gsub(/^\/*/, '')}") if uri.scheme.nil?
    return nil if uri.scheme.nil? or uri.host.nil?
    uri.normalize.to_s
  end

  def time_zone
    return 'UTC' if region.time_zone.nil? or Time.find_zone(region.time_zone).nil?
    region.time_zone
  end

  def read_day_info(key)
    self.day_info[key]
  end

  def day_info
    {}.tap do |day_info|
      detailed_hours = JSON.parse(detailed_hours_json) rescue {}
      return if detailed_hours.empty?
      now = Time.new

      (0..6).each do |index|
        value = detailed_hours[index.to_s]
        next if value.nil?

        start = value['start']
        stop = value['end']
        next if start.nil? or stop.nil?

        time_in_zone = Time.find_zone(time_zone)

        day_info["day#{index}_status"] = value['status'].to_i
        day_info["day#{index}_start"] = time_in_zone.parse(start).change(year: now.year, month: now.month, day: now.day)
        day_info["day#{index}_end"] = time_in_zone.parse(stop).change(year: now.year, month: now.month, day: now.day)
      end
    end
  end

  def clean_address
    address.gsub(/\r/, ' ').gsub(/\n/, ' ')
  end

  def mappable_address
    clean_address.tr(' ', '+')
  end

  private

  def detailed_hours_cannot_end_before_start
    (0..6).each do |index|
      if open_on_day? index
        prefix = 'day'+index.to_s
        if read_day_info("#{prefix}_start") > read_day_info("#{prefix}_end")
          errors.add("#{prefix}_status", 'must have an end time AFTER the start time')
        end
      end
    end
  end

  def populate_receipt_key
    self.receipt_key = (0...8).map { ('a'..'z').to_a[rand(26)] }.join if self.receipt_key.blank?
  end

  def populate_detailed_hours_json_before_save
    hours_info = {}
    (0..6).each do |index|
      start = read_day_info("day#{index}_start")
      stop = read_day_info("day#{index}_end")
      next if start.nil? or stop.nil?

      hours_info[index] = {
        status: read_day_info("day#{index}_status").to_s,
        # save these with the timezone on them!
        start: start.to_formatted_s(:rfc822),
        end: stop.to_formatted_s(:rfc822)
      }
    end
    self.detailed_hours_json = hours_info.to_json
  end

  def init_detailed_hours_json
    self.detailed_hours_json ||= {}
  end
end
