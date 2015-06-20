class LogVolunteer < ActiveRecord::Base

  belongs_to :log
  belongs_to :volunteer

  attr_accessible :log_id, :volunteer_id, :active, :log, :volunteer, :covering

  accepts_nested_attributes_for :volunteer

end
