class TransportTypesController < ApplicationController
  active_scaffold :transport_type do |conf|
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
