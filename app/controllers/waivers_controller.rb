class WaiversController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :skip_authorization, only: [:new, :create]

  def new
    @region = current_volunteer.main_region
  end

  def create
    if !accepted_waiver?
      redirect_to new_waiver_url, alert: "Accept the waiver by checking 'Check to sign electronically'"
    elsif SignWaiver.call(volunteer: current_volunteer, signed_at: Time.zone.now).success?
      redirect_to root_url, notice: 'Waiver signed!'
    else
      redirect_to new_waiver_url, alert: "There was an error signing the waiver"
    end
  end

  private

  def accepted_waiver?
    params[:accept].present?
  end
end
