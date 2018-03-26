class SchedulePart < ActiveRecord::Base
  belongs_to :schedule
  belongs_to :food_type
  attr_accessible :required, :schedule_id, :food_type_id
end
