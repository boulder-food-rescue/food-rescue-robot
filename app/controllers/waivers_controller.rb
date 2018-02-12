class WaiversController < ApplicationController
  before_filter :authenticate_volunteer!

  def new
    @region = current_volunteer.main_region
  end

  def create
    if !accepted_waiver?
      redirect_to new_waiver_url, alert: "Accept the waiver by checking 'Check to sign electronically'"
    elsif SignWaiver.call(volunteer: current_volunteer, signed_at: Time.zone.now).success?
      redirect_to root_url, notice: 'Waiver signed!'
    else
      redirect_to new_waiver_url, alert: 'There was an error signing the waiver'
    end
  end

  def new_driver_waiver
    @region = current_volunteer.main_region
  end

  def create_driver
    if !accepted_waiver?
      redirect_to driver_waiver_path, alert: "Accept the waiver by checking 'Check to sign electronically'"
    elsif SignDriverWaiver.call(volunteer: current_volunteer, signed_at: Time.zone.now).success?
      redirect_to driver_waiver_path, notice: 'Waiver signed!'
    else
      redirect_to driver_waiver_path, alert: 'There was an error signing the waiver'
    end
  end
  private

  def accepted_waiver?
    params[:accept].present?
  end
end
