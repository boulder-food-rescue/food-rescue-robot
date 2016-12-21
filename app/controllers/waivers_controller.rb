class WaiversController < ApplicationController
  before_filter :authenticate_volunteer!

  def new
    @region = current_volunteer.main_region
  end

  def create
    if accepted_waiver?
      sign_waiver
      redirect_to root_url, notice: 'Waiver signed!'
    else
      redirect_to new_waiver_url, alert: "Accept the waiver by checking 'Check to sign electronically'"
    end
  end

  private

  def accepted_waiver?
    params[:accept].present?
  end

  def sign_waiver
    current_volunteer.waiver_signed    = true
    current_volunteer.waiver_signed_at = Time.zone.now

    current_volunteer.save
  end
end
