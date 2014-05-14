class ScheduleChain < ActiveRecord::Base

	has_many :schedule_volunteers
	has_many :volunteers, :through => :schedule_volunteers, 
           :conditions=>{"schedule_volunteers.active"=>true}
	has_many :schedules
  has_many :logs
	belongs_to :transport_type
	belongs_to :region
	
	attr_accessible :region_id, :irregular, :backup, :transport_type_id, :weekdays,
									:day_of_week, :detailed_start_time, :detailed_stop_time, 
									:detailed_date, :frequency, :temporary, :difficulty_rating, :expected_weight,
									:hilliness, :schedule_volunteers, :schedule_volunteers_attributes, :scale_type_ids,
									:schedule_ids, :admin_notes, :public_notes, :schedules, :schedule
	
	accepts_nested_attributes_for :schedule_volunteers

  Hilliness = ["Flat","Mostly Flat","Some Small Hills","Hilly for Reals","Mountaineering"]
  Difficulty = ["Easiest","Typical","Challenging","Most Difficult"]

	after_save{ |record|
    record.schedule_volunteers.each{ |sv|
			sv.destroy if sv.volunteer_id.blank?
		}
  }

    # list all the schedules chains that have at least two stops, but don't have any volunteer
  def self.unassigned_in_regions region_id_list
    conditions = {}
    conditions[:region_id] = region_id_list if region_id_list.length > 0
    self.includes(:schedule_volunteers).keep_if { |schedule| 
        schedule.volunteers.count == 0 and schedule.functional?
    }
		conditions
  end
	
		# does the schedule chain start with a pickup and end with a dropoff?
	def functional?
		if not self.schedules.first.nil?
			self.schedules.rank(:position).first.is_pickup_stop? and not self.schedules.rank(:position).last.is_pickup_stop?
		else
			false
		end
	end

  # list all the schedules that don't have active volunteers
  # clarification: (in my regions) and (temporary or (no volunteers and last stop is dropoff))
  def self.open_in_regions region_id_list
    schedules = ScheduleChain.where(:irregular=>false).where(:region_id=>region_id_list) if region_id_list.length > 0
    schedules.keep_if do |schedule|
			unless not schedule.functional?
      	schedule.temporary or ((schedule.volunteers.size == 0) and (not schedule.schedules.last.is_pickup_stop?))
    	else
				false
			end
		end
    schedules
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
    frequency=='one-time'
  end

  def weekly?
    frequency=='weekly'
  end

  def max_weight
    Log.where("schedule_id = ?",self.id).collect{ |l| l.summed_weight }.compact.max
  end

  def mean_weight
    ls = Log.where("schedule_id = ?",self.id).collect{ |l| l.summed_weight }
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
    self.schedules.select{ |stop| not stop.is_pickup_stop? }
  end

end
