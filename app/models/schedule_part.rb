class SchedulePart < ActiveRecord::Base
  belongs_to :schedule
  belongs_to :food_type
  belongs_to :location_admin

  attr_accessible :required, :schedule_id, :food_type_id, :location_admin_id
end
