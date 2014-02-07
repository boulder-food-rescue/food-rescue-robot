class SchedulePart < ActiveRecord::Base
  belongs_to :schedule
  belongs_to :food_type
  belongs_to :scale_type
  attr_accessible :required
end
