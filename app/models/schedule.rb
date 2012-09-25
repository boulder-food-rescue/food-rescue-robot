class Schedule < ActiveRecord::Base
  belongs_to :volunteer
  belongs_to :prior_volunteer, :class_name => "Volunteer", :foreign_key => "prior_volunteer_id"
  belongs_to :donor, :class_name => "Location", :foreign_key => "donor_id"
  belongs_to :recipient, :class_name => "Location", :foreign_key => "recipient_id"
  belongs_to :transport_type
  belongs_to :region
  has_and_belongs_to_many :food_types

  attr_accessible :region_id, :volunteer_id, :irregular, :backup, :transport_type_id, :food_type_ids, :weekdays, :admin_notes, :day_of_week, :donor_id, :needs_training, :prior_volunteer_id, :public_notes, :recipient_id, :time_start, :time_stop
end
