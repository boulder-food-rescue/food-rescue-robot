class LocationAdminsController < ApplicationController
  before_filter :authenticate_location_admin!


  def home
    @location_name = current_location_admin.locations
    if @location_name.blank?
      redirect_to new_location_association_location_admins_path
    end
    render :home

  end
  def new

  end
  def index

  end
  def edit

  end
  def new_location_association
  end
end