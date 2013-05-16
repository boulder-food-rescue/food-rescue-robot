class FoodType < ActiveRecord::Base
  attr_accessible :name, :region_id
  has_many :schedules, :through => :schedule_parts
  has_many :schedule_parts
  has_many :log_parts
  has_many :logs, :through => :log_parts
  belongs_to :region

  def self.regional(region)
    where("region_id = ?",region.id)
  end
end
