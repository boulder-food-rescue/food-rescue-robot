class ScheduleChain < ActiveRecord::Base

	has_many :schedule_volunteers
	has_many :volunteers, :through => :schedule_volunteers, 
           :conditions=>{"schedule_volunteers.active"=>true}
	has_many :schedules
	belongs_to :transport_type
	belongs_to :region
	
	attr_accessible :region_id, :irregular, :backup, :transport_type_id, :weekdays, :admin_notes,
									:day_of_week, :public_notes, :detailed_start_time, :detailed_stop_time, 
									:detailed_date, :frequency, :temporary, :difficulty_rating, :expected_weight,
									:hilliness, :schedule_volunteers, :schedule_volunteer_attributes, :scale_type_ids,
									:schedule_ids
	
	accepts_nested_attributes_for :schedule_volunteers

  Hilliness = ["Flat","Mostly Flat","Some Small Hills","Hilly for Reals","Mountaineering"]
  Difficulty = ["Easiest","Typical","Challenging","Most Difficult"]

	after_save{ |record|
    record.schedule_volunteers.each{ |sv|
      sv.destroy if sv.volunteer_id.blank?
    }
  }


