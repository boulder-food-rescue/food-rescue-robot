class RegionsController < ApplicationController
  active_scaffold :region do |conf|
    conf.columns = [:name,:address,:lat,:lng,:notes,:website]
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
