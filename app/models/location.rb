# frozen_string_literal: true

class Location < ActiveRecord::Base
  # TODO: MOVE TO ENUM
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

  geocoded_by :address, latitude: :lat, longitude: :lng # can also be an IP address
  acts_as_gmappable process_geocoding: false, lat: 'lat', lng: 'lng', address: 'address'

  after_initialize :init_detailed_hours
  before_save :populate_detailed_hours_json_before_save
  before_save :populate_receipt_key
  after_validation :geocode, on: :create
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

  def donor?
    location_type == LOCATION_TYPES.invert['Donor']
  end

  def hub?
    location_type == LOCATION_TYPES.invert['Hub']
  end

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
      'picture' => self.donor? ? 'http://maps.gstatic.com/intl/en_ALL/mapfiles/dd-start.png' :
                                   'http://maps.gstatic.com/intl/en_ALL/mapfiles/dd-end.png' # string,  mandatory
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
    [read_day_info("day#{index}_start"), read_day_info("day#{index}_end")]
  end

  def open_on_day?(index)
    read_day_info('day'+index.to_s+'_status') == 1
  end

  def populate_detailed_hours_from_form(params)
    (0..6).each do |index|
      prefix = 'day'+index.to_s
      write_day_info(prefix+'_status', params[prefix]['status'].to_i)
      write_day_info(prefix+'_start',
                     Time.find_zone(self.time_zone).parse( params[prefix]['start']['hour']+':'+params[prefix]['start']['minute'] )
                    )
      write_day_info(prefix+'_end',
                     Time.find_zone(self.time_zone).parse( params[prefix]['end']['hour']+':'+params[prefix]['end']['minute'] )
                    )
    end
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
    return 'UTC' if region.try(:time_zone).nil? || Time.find_zone(region.time_zone).nil?
    region.time_zone
  end

  def read_day_info(key)
    self.day_info[key]
  end

  def day_info
    @day_info = {} if @day_info.nil?
    @day_info
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
      if open_on_day?(index)
        if read_day_info("day#{index}_start") > read_day_info("day#{index}_end")
          errors.add("day#{index}_status", 'must have an end time AFTER the start time')
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
      prefix = 'day' + index.to_s + '_'
      start = read_day_info(prefix + 'start')
      stop = read_day_info(prefix + 'end')
      next if start.nil? || stop.nil?
      hours_info[index] = {
        status: read_day_info(prefix+'status').to_s,
        # save these with the timezone on them!
        start: start.to_formatted_s(:rfc822),
        end: stop.to_formatted_s(:rfc822)
      }
    end
    self.detailed_hours_json = hours_info.to_json
  end

  def init_detailed_hours
    begin
      return if self.detailed_hours_json.nil?
    rescue ActiveModel::MissingAttributeError
      return
    end
    detailed_hours = JSON.parse(self.detailed_hours_json)
    return if detailed_hours.empty?
    now = Time.new
    @day_info = {}
    (0..6).each do |index|
      prefix = 'day'+index.to_s+'_'
      next if detailed_hours[index.to_s].nil?
      start = detailed_hours[index.to_s]['start']
      stop = detailed_hours[index.to_s]['end']
      next if start.nil? or stop.nil?
      write_day_info( prefix+'status', detailed_hours[index.to_s]['status'].to_i )
      # carefully set start time
      time = Time.find_zone(self.time_zone).parse( start )
      time = time.change(:year=>now.year, :month=>now.month, :day=>now.day)
      write_day_info( prefix+'start', time)
      # carefully set end time
      time = Time.find_zone(self.time_zone).parse( stop )
      time = time.change(:year=>now.year, :month=>now.month, :day=>now.day)
      write_day_info( prefix+'end', time )
    end
  end

  def write_day_info(key, value)
    self.day_info[key] = value
  end
end
