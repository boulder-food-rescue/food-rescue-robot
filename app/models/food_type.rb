class FoodType < ActiveRecord::Base
  attr_accessible :name
  has_and_belongs_to_many :schedules

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
end
