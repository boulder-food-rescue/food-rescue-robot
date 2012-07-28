class FoodTypesController < ApplicationController
  active_scaffold :food_type do |conf|
    conf.columns = [:name]
  end
  def create_authorized?
    current_volunteer.super_admin?
  end
  def update_authorized?(record=nil)
    current_volunteer.super_admin?
  end
  def delete_authorized?(record=nil)
    current_volunteer.super_admin?
  end
end 
