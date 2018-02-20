class WaiversController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :get_volunteer_signee

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
    @volunteer_signee = @volunteer_signee
    @volunteer_region = @volunteer_region
  end

  def create_driver
    if !accepted_waiver?
      redirect_to driver_waiver_path, alert: "Accept the waiver by checking 'Check to sign electronically'"
    elsif signed_waiver_success?
      redirect_to root_url, notice: 'Waiver signed!'
    else
      redirect_to driver_waiver_path, alert: 'There was an error signing the waiver'
    end
  end

  private

  def accepted_waiver?
    params[:accept].present? || params[:admin_accept].present?
  end

  def signed_waiver_success?
    if @volunteer_signee.blank?
      SignDriverWaiver.call(volunteer_signee: current_volunteer, signed_at: Time.zone.now).success?
    else
      SignDriverWaiver.call(volunteer_signee: @volunteer_signee, signed_at: Time.zone.now, admin_signee: current_volunteer).success?
    end
  end

  def get_volunteer_signee
    if params[:volunteer_id].present?
      @volunteer_signee = Volunteer.find(params[:volunteer_id])
      @volunteer_region = @volunteer_signee.main_region
    else
      @volunteer_signee = current_volunteer
      @volunteer_region = current_volunteer.main_region
    end
  end
end
