class AvailabilitiesController < ApplicationController
  def index
  end

  def new
    @volunteer = Volunteer.find(params[:volunteer_id])

    @availability = Availability.new

  end

  def create
    # retreive the data from checkboxes
    # send data to appropriate models and db
# @user = User.new(params[:user])
  #  params[:availabilities].each do |availability|
      # grab the key of each availability, sned it to db
      @availability = params[:availability]
      #params.require(:availability).permit(:days:[])
  end

  def destroy
  end

  def update
    @availability = Availability.find(params[:id])


  end
end
