class ScheduleVolunteer < ActiveRecord::Base
	
	belongs_to :schedule
	belongs_to :volunteer
  
  attr_accessible :schedule_id, :volunteer_id, :active

	accepts_nested_attributes_for :volunteer	

end
