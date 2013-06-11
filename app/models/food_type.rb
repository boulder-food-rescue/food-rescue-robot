class FoodType < ActiveRecord::Base
  attr_accessible :name
  has_and_belongs_to_many :schedules
  has_many :log_parts
  has_many :logs, :through => :log_parts
  belongs_to :region

  # ActiveScaffold CRUD-level restrictions
  def authorized_for_update?
    current_user.super_admin?
  end
  def authorized_for_create?
    current_user.super_admin?
  end
  def authorized_for_delete?
    current_user.super_admin?
  end

  def self.regional(region)
    where("region_id = ?",region.id)
  end
end
