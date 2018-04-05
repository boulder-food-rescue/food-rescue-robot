class AvailabilitiesController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only, only: :index

  def index
    @avails = Availability.all

  end

  def new
    @volunteer = Volunteer.find(params[:volunteer_id])
    @availability = Availability.new(params[:availability])
    @weekdays = ["Monday","Tuesday","Wednesday","Thursday","Friday","Saturday","Sunday"]
    @timeslots = ["Morning","Afternoon","Evening"]
  end

  def create
    v = Volunteer.find(params[:volunteer_id])
    v.availabilities.destroy_all
    saved = v.availabilities
    params[:availability].each do |selection|
      day = eval(selection)[:day]
      time = eval(selection)[:time]
      v.availabilities << Availability.new(day: day, time: time)
    end
    redirect_to(root_path)
  end

end
