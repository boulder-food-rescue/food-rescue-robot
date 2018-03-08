class FoodType < ActiveRecord::Base
  belongs_to :region

  has_many :schedule_parts
  has_many :schedules, through: :schedule_parts
  has_many :log_parts
  has_many :logs, through: :log_parts

  default_scope { where(active: true) }
  scope :active, -> { where(active: true) }
  scope :regional, ->(ids) { where(region_id: ids) }

  attr_accessible :name, :region_id
end
