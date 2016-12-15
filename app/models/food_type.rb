class FoodType < ActiveRecord::Base
  attr_accessible :name, :region_id

  belongs_to :region

  has_many :schedule_parts
  has_many :schedules, through: :schedule_parts
  has_many :log_parts
  has_many :logs, through: :log_parts

  default_scope { where(active: true) }
end
