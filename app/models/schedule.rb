class Schedule < ActiveRecord::Base
  belongs_to :volunteer
  attr_accessible :admin_notes, :day_of_week, :donor_id, :needs_training, :prior_volunteer_id, :public_notes, :recipient_id, :time_start, :time_stop
end
