class AvailabilitiesController < ApplicationController
  def new
    @volunteer = Volunteer.find(params[:volunteer_id])
    @availability = Availability.new(params[:availability])
    @weekdays = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    @timeslots = ["Morning","Afternoon","Evening"]
  end

  def create
    params[:availability].each do |selection|
      volunteer = Volunteer.find(params[:volunteer_id])
      day = eval(selection)[:day]
      time = eval(selection)[:time]
      volunteer.availabilities << Availability.new(day: day, time: time)
    end
    redirect_to(root_path)
  end

  def destroy
  end

  def update
    #@availability = Availability.find(params[:id])
  end

  #params.require(:availability).permit(:days:[])
end
