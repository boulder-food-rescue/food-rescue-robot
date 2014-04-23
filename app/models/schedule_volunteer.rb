class ScheduleVolunteer < ActiveRecord::Base
	
	belongs_to :schedule_chain
	belongs_to :volunteer
  
  attr_accessible :schedule_chain_id, :volunteer_id, :active

	accepts_nested_attributes_for :volunteer	

end
