class ScheduleChain < ActiveRecord::Base

  default_scope { where(active:true) }

  has_many :schedule_volunteers
  has_many :volunteers, :through => :schedule_volunteers,
           :conditions=>{"schedule_volunteers.active"=>true}
  has_many :schedules
  has_many :locations, :through => :schedules
  has_many :logs
  belongs_to :transport_type
  belongs_to :scale_type
  belongs_to :region

  attr_accessible :region_id, :irregular, :backup, :transport_type_id,
		:day_of_week, :detailed_start_time, :detailed_stop_time,
	 	:detailed_date, :frequency, :temporary, :difficulty_rating, :expected_weight,
		:hilliness, :schedule_volunteers, :schedule_volunteers_attributes, :scale_type_ids,
		:schedule_ids, :admin_notes, :public_notes, :schedules, :schedule, :schedule_volunteers,
    :schedules_attributes, :num_volunteers, :active

  accepts_nested_attributes_for :schedule_volunteers
  accepts_nested_attributes_for :schedules

  Hilliness = ["Flat","Mostly Flat","Some Small Hills","Hilly for Reals","Mountaineering"]
  Difficulty = ["Easiest","Typical","Challenging","Most Difficult"]

  after_save{ |record|
    record.schedule_volunteers.each{ |sv|
      sv.destroy if sv.volunteer_id.blank?
    }
  }

  def covered?
    self.volunteers.length >= self.num_volunteers
  end

  # does the schedule chain start with a pickup and end with a dropoff?
  def functional?
    not self.schedules.empty? and self.schedules.first.is_pickup_stop? and self.schedules.last.is_drop_stop?
  end

  def mappable?
    self.functional? and not self.schedules.any?{ |s| s.location.nil? or s.location.address.blank? }
  end

  # list all the schedules that don't have active volunteers
  # clarification: (in my regions) and (temporary or (no volunteers and last stop is dropoff))
  def self.open_in_regions region_id_list
    schedules = ScheduleChain.where(:irregular=>false).where(:region_id=>region_id_list) if region_id_list.length > 0
    return [] if schedules.nil?
    schedules.keep_if do |schedule|
      unless not schedule.functional?
      	schedule.temporary or not schedule.covered?
      else
	      false
      end
    end
    schedules
  end

  def self.for_location(loc)
    if loc.is_donor
      ScheduleChain.for_donor(loc)
    else
      ScheduleChain.for_recipient(loc)
    end
  end

  def self.for_donor(d)
    Schedule.joins(:location).where("locations.location_type = ? AND locations.id = ?",Location::LOCATION_TYPES.invert["Donor"],d.id).collect{ |s| s.schedule_chain }.uniq
  end

  def self.for_recipient(r)
    Schedule.joins(:location).where("NOT locations.location_type = ? AND locations.id = ?",Location::LOCATION_TYPES.invert["Recipient"],r.id).collect{ |s| s.schedule_chain }.uniq
  end

  def food_types
    self.schedules.collect{ |s| s.food_types }.flatten.uniq
  end

  def has_volunteers?
    self.volunteers.count > 0
  end

  def no_volunteers?
    self.volunteers.count == 0
  end

  def volunteers_needing_training?
    somebody_needs_training = false
    self.volunteers.each { |volunteer| somebody_needs_training |= volunteer.needs_training? }
    somebody_needs_training
  end

  def prior_volunteers
    self.schedule_volunteers.collect{ |sv| (not sv.active) ? sv.volunteer : nil }.compact
  end

  def has_volunteer? volunteer
    return false if volunteer.nil?
    self.volunteers.collect { |v| v.id }.include? volunteer.id
  end

  def one_time?
    frequency == 'one-time'
  end

  def weekly?
    frequency == 'weekly'
  end

  def max_weight
    Log.where("schedule_chain_id = ?", self.id).collect{ |l| l.summed_weight }.compact.max
  end

  def mean_weight
    ls = Log.where("schedule_chain_id = ?",self.id).collect{ |l| l.summed_weight }
    ls.length == 0 ? nil : ls.sum/ls.length
  end

  def next_pickup_time
    next_pickup_times = nil
    if self.weekly? and not self.irregular
      next_pickup = Time.zone.today
      next_pickup += 1 if self.day_of_week == next_pickup.wday and
                          self.detailed_start_time.strftime("%H%m").to_i < Time.zone.now.strftime("%H%m").to_i
      while next_pickup.wday != self.day_of_week
        next_pickup += 1
      end
      time_start_hour = self.detailed_start_time.hour
      time_start_minute = self.detailed_start_time.min
      time_stop_hour = self.detailed_stop_time.hour
      time_stop_minute = self.detailed_stop_time.min
      next_pickup_start = Time.new(next_pickup.year,next_pickup.month,next_pickup.day,time_start_hour,time_start_minute)
      next_pickup_stop = Time.new(next_pickup.year,next_pickup.month,next_pickup.day,time_stop_hour,time_stop_minute)
      next_pickup_times = {:start=>next_pickup_start, :stop=>next_pickup_stop}
    end
    next_pickup_times
  end

  def donor_stops
    self.schedules.select{ |stop| stop.is_pickup_stop? }
  end

  def recipient_stops
    self.schedules.select{ |stop| stop.is_drop_stop? }
  end

  def donors
    self.donor_stops.collect{ |ds| ds.location }
  end

  def recipients
    self.recipient_stops.collect{ |rs| rs.location }
  end

  def from_to_name
    schedule_1 = schedules.first
    schedule_2 = schedules.last
    "#{schedule_1.location.try(:name)} to #{schedule_2.location.try(:name)}"
  end

  def related_shifts
    lids = self.donors.collect{ |d|
      d.location_type == Location::LOCATION_TYPES.invert["Hub"] ? nil : d.id
    }.compact
    return [] if lids.empty?
    return Schedule.where("location_id IN (#{lids.join(",")}) AND schedule_chain_id!=?", self.id).reject{ |x|
      x.schedule_chain.nil?
    }
  end

end
