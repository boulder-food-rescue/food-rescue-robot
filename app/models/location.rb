class Location < ActiveRecord::Base
  belongs_to :region
  has_many :log_donors
  has_many :logs, :through => :log_donors
  geocoded_by :address, :latitude => :lat, :longitude => :lng   # can also be an IP address
  acts_as_gmappable :process_geocoding => false, :lat => "lat", :lng => "lng", :address => "address"

  after_initialize :init_detailed_hours
  before_save :populate_detailed_hours_json_before_save
  after_validation :geocode

  default_scope order('locations.name ASC')

  validate :detailed_hours_cannot_end_before_start

  attr_accessible :region_id, :address, :twitter_handle, :admin_notes, :contact, :donor_type, :hours, 
                  :is_donor, :lat, :lng, :name, :public_notes, :recip_category, :website, :receipt_key,
                  :email, :phone, :equipment_storage_info, :food_storage_info, :entry_info, :exit_info,
                  :onsite_contact_info

  scope :donors, where(:is_donor=>true)
  scope :recipients, where(:is_donor=>false)

  def weight_stats
    w = Log.where("donor_id = ? OR recipient_id = ?",self.id,self.id).collect{ |l| l.summed_weight }
    nozeroes = w.collect{ |e| e == 0 ? nil : e }.compact
    return {:mean => nozeroes.mean, :median => nozeroes.median, :std => nozeroes.std, :n => w.length, 
            :zeroes => (w.length-nozeroes.length) }
  end

  def donor?
    return is_donor
  end

  def gmaps4rails_title
    self.name
  end
  
  def gmaps4rails_infowindow
    ret = "<span style=\"font-weight: bold;color: darkblue;\">#{self.name}</span><br>"
    ret += self.address.gsub("\n","<br>") unless self.address.nil?
    ret += "<br>"
    ret += self.contact.gsub("\n","<br>") unless self.contact.nil?
    ret += "<br>"
    ret += self.hours.gsub("\n","<br>") unless self.hours.nil?
    ret += "<br>"
    ret += "<a href=\"#{self.website}\">website</a>" unless self.website.nil?
    ret
  end
  
  def gmaps4rails_marker_picture
   {
     "picture" => self.is_donor ? "http://maps.gstatic.com/intl/en_ALL/mapfiles/dd-start.png" : 
                                  "http://maps.gstatic.com/intl/en_ALL/mapfiles/dd-end.png"          # string,  mandatory
   }
  end

  # this has to be smart about time zones
  def open? time=nil
    time = Time.new if time.nil?
    time = time.in_time_zone(self.time_zone)
    day_index = time.wday
    return unless open_on_day? day_index
    hours = hours_on_day day_index
    (time > hours[0]) && (time < hours[1])
  end

  def hours_on_day index
    [ read_day_info("day"+index.to_s+"_start") , read_day_info("day"+index.to_s+"_end") ]
  end

  def open_on_day? index
    read_day_info('day'+index.to_s+'_status') == 1
  end

  def populate_detailed_hours_from_form params
    return unless using_detailed_hours?
    (0..6).each do |index|
      prefix = "day"+index.to_s
      write_day_info(prefix+"_status", params[prefix]["status"].to_i)
      write_day_info(prefix+"_start", 
        Time.find_zone(self.time_zone).parse( params[prefix]['start']['hour']+":"+params[prefix]['start']['minute'] )
      )
      write_day_info(prefix+"_end", 
        Time.find_zone(self.time_zone).parse( params[prefix]['end']['hour']+":"+params[prefix]['end']['minute'] )
      )
    end
    populate_detailed_hours_json_before_save
  end

  def time_zone
    return 'UTC' if region.time_zone.nil? or Time.find_zone(region.time_zone).nil?
    region.time_zone
  end

  def read_day_info key
    self.day_info[key]
  end

  def day_info
    @day_info = {} if @day_info.nil?
    @day_info
  end

  private 
  
    def using_detailed_hours? 
      Webapp::Application.config.use_detailed_hours
    end

    def detailed_hours_cannot_end_before_start
      (0..6).each do |index|
        if open_on_day? index
          prefix = "day"+index.to_s
          if read_day_info(prefix+"_start") > read_day_info(prefix+"_start")
            errors.add(prefix+"_status","must have an end time AFTER the start time")
          end
        end
      end
    end

    def populate_detailed_hours_json_before_save
      return unless using_detailed_hours?
      hours_info = {}
      (0..6).each do |index|
        prefix = "day"+index.to_s+"_"
        start = read_day_info(prefix+"start")
        stop = read_day_info(prefix+"end")
        next if start.nil? or stop.nil?
        hours_info[index] = {
          :status => read_day_info(prefix+"status").to_s,
          # save these with the timezone on them!
          :start => start.to_formatted_s(:rfc822),
          :end => stop.to_formatted_s(:rfc822)
        }
      end
      self.detailed_hours_json = hours_info.to_json
    end

    def init_detailed_hours
      return unless using_detailed_hours?
      return if detailed_hours_json.nil?
      detailed_hours = JSON.parse(detailed_hours_json)
      return if detailed_hours.empty?
      now = Time.new
      @day_info = {}
      (0..6).each do |index|
        prefix = "day"+index.to_s+"_"
        next if detailed_hours[index.to_s].nil?
        start = detailed_hours[index.to_s]['start']
        stop = detailed_hours[index.to_s]['end']
        next if start.nil? or stop.nil?
        write_day_info( prefix+"status", detailed_hours[index.to_s]['status'].to_i )
        # carefully set start time
        t = Time.find_zone(self.time_zone).parse( start )
        t = t.change(:year=>now.year,:month=>now.month, :day=>now.day)
        write_day_info( prefix+"start", t )
        # carefully set end time
        t = Time.find_zone(self.time_zone).parse( stop )
        t = t.change(:year=>now.year,:month=>now.month, :day=>now.day)
        write_day_info( prefix+"end", t )
      end
    end

    def write_day_info key, value
      self.day_info[key] = value
    end

end
