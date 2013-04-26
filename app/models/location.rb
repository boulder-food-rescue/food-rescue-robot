class Location < ActiveRecord::Base
  belongs_to :region
  geocoded_by :address, :latitude => :lat, :longitude => :lng   # can also be an IP address
  acts_as_gmappable :process_geocoding => false, :lat => "lat", :lng => "lng", :address => "address"

  after_initialize :init_detailed_hours
  before_save :populate_detailed_hours_json_before_save
  after_validation :geocode

  validate :detailed_hours_cannot_end_before_start

  attr_accessible :region_id, :address, :twitter_handle, :admin_notes, :contact, :donor_type, :hours, 
                  :is_donor, :lat, :lng, :name, :public_notes, :recip_category, :website, :receipt_key,
                  :email, :phone
  # fake attributes, actually encoded as json into one field
  attr_accessor :day0_status,:day0_start,:day0_end,
                  :day1_status,:day1_start,:day1_end,
                  :day2_status,:day2_start,:day2_end,
                  :day3_status,:day3_start,:day3_end,
                  :day4_status,:day4_start,:day4_end,
                  :day5_status,:day5_start,:day5_end,
                  :day6_status,:day6_start,:day6_end

  scope :donors, where(:is_donor=>true)
  scope :recipients, where(:is_donor=>false)

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

  def open_on_day? index
    read_attribute('day'+index.to_s+'_status') == 1
  end

  def using_detailed_hours 
    Webapp::Application.config.use_detailed_hours
  end

  def detailed_hours_cannot_end_before_start
    (0..6).each do |index|
      if open_on_day? index
        prefix = "day"+index.to_s
        if read_attribute(prefix+"_start") > read_attribute(prefix+"_start")
          errors.add(prefix+"_status","must have an end time AFTER the start time")
        end
      end
    end
  end

  def populate_detailed_hours_json_before_save
    return unless using_detailed_hours
    hours_info = {}
    (0..6).each do |index|
      prefix = "day"+index.to_s+"_"
      hours_info[index] = {
        :status => read_attribute(prefix+"status"),
        :start => read_attribute(prefix+"start"),
        :end => read_attribute(prefix+"end")
      }
    end
    write_attribute(:detailed_hours_json, hours_info.to_json)
  end

  def populate_detailed_hours_from_form params
    return unless using_detailed_hours
    puts params.to_yaml
    (0..6).each do |index|
      prefix = "day"+index.to_s
      write_attribute(prefix+"_status", params[prefix]["status"].to_i)
      write_attribute(prefix+"_start", Time.parse( params[prefix]['start']['hour']+":"+params[prefix]['start']['minute']) )
      write_attribute(prefix+"_end", Time.parse( params[prefix]['end']['hour']+":"+params[prefix]['end']['minute']) )
    end
  end

  def init_detailed_hours
    return unless using_detailed_hours
    return if detailed_hours_json.nil?
    detailed_hours = JSON.parse(detailed_hours_json)
    (0..6).each do |index|
      prefix = "day"+index.to_s+"_"
      write_attribute(prefix+"status",detailed_hours[index.to_s]['status'].to_i)
      write_attribute(prefix+"start",Time.parse(detailed_hours[index.to_s]['start']))
      write_attribute(prefix+"end",Time.parse(detailed_hours[index.to_s]['end']))
    end
  end

end
