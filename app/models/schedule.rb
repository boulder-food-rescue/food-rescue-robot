class Schedule < ActiveRecord::Base

	include RankedModel
	
  has_many :schedule_volunteers
  has_many :logs
	belongs_to :location
	belongs_to :schedule_chain
	ranks :position, :with_same => :schedule_chain_id
  has_many :schedule_parts
  has_many :food_types, :through => :schedule_parts

  attr_accessible :food_type_ids, :location_id, :public_notes, :admin_notes, :expected_weight 

    # list all the schedules that have donors and recipients, but don't have any volunteer
  def self.unassigned_in_regions region_id_list
    conditions = {}
    conditions[:region_id] = region_id_list if region_id_list.length > 0
    self.includes(:schedule_volunteers).where("donor_id IS NOT NULL").
      where("recipient_id IS NOT NULL").keep_if { |schedule| 
        schedule.volunteers.count > 0
    }
  end

  # list all the schedules that don't have active volunteers
  # clarification: (in my regions) and (temporary or (no volunteers and recipient is set))
  def self.open_in_regions region_id_list
    schedules = Schedule.where(:irregular=>false)
    schedules = Schedule.where(:region_id=>region_id_list) if region_id_list.length > 0
    schedules.keep_if do |schedule|
      schedule.temporary or ((schedule.volunteers.size == 0) and (not schedule.recipient_id.nil?))
    end
    schedules
  end

	def is_pickup_stop?
		return self.location.donor?
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
end
