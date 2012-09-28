class SchedulesController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only, :only => [:fast_schedule,:today,:tomorrow,:yesterday,:edit,:update,:create,:new]

  def open
    index(nil,nil,"volunteer_id IS NULL and recipient_id IS NOT NULL")
  end
  def mine
    index(nil,current_volunteer.id)
  end

  def index(day_of_week=nil,volunteer_id=nil,otherq=nil)
    dowq = day_of_week.nil? ? "" : "AND day_of_week = #{day_of_week.to_i}"
    volq = volunteer_id.nil? ? "" : "AND volunteer_id = #{volunteer_id}"
    otherq = otherq.nil? ? "" : "AND #{otherq}"
    @volunteer_schedules = Schedule.where("region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")}) #{dowq} #{volq} #{otherq}")
    @regions = Region.all
    if current_volunteer.super_admin?
      @my_admin_regions = @regions
    else
      @my_admin_regions = current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
    end
    render :index
  end

  def show
    @s = Schedule.find(params[:id])
  end

  def today
    index(Date.today.wday)
  end
  def tomorrow
    index(Date.today.wday+1 % 6)
  end
  def yesterday
    day_of_week = Date.today.wday - 1
    day_of_week = 6 if day_of_week < 0
    index(day_of_week)
  end

  def destroy
    @s = Schedule.find(params[:id])
    unless current_volunteer.super_admin? or current_volunteer.region_admin? @s.region
      flash[:notice] = "Not authorized to delete schedule items for that region"
      redirect_to(root_path)
      return
    end
    @s.destroy
    redirect_to(request.referrer)
  end

  def new
    @region = Region.find(params[:region_id])
    unless current_volunteer.super_admin? or current_volunteer.region_admin? @region
      flash[:notice] = "Not authorized to create schedule items for that region"
      redirect_to(root_path)
      return
    end
    @schedule = Schedule.new
    @action = "create"
    render :new
  end

  def create
    @schedule = Schedule.new(params[:schedule])
    unless current_volunteer.super_admin? or current_volunteer.region_admin? @schedule.region
      flash[:notice] = "Not authorized to create schedule items for that region"
      redirect_to(root_path)
      return
    end
    if @schedule.save
      flash[:notice] = "Created successfully"
      index
    else
      flash[:notice] = "Didn't save successfully :("
      render :new
    end
  end

  def edit
    @schedule = Schedule.find(params[:id])
    unless current_volunteer.super_admin? or current_volunteer.region_admin? @schedule.region
      flash[:notice] = "Not authorized to edit schedule items for that region"
      redirect_to(root_path)
      return
    end
    @region = @schedule.region
    @action = "update"
  end

  def update
    @schedule = Schedule.find(params[:id])
    unless current_volunteer.super_admin? or current_volunteer.region_admin? @schedule.region
      flash[:notice] = "Not authorized to edit schedule items for that region"
      redirect_to(root_path)
      return
    end
    if @schedule.update_attributes(params[:schedule])
      flash[:notice] = "Updated Successfully"
      index
    else
      flash[:notice] = "Update failed :("
      render :edit
    end
  end

  def take
    s = Schedule.find(params[:id])
    if current_volunteer.regions.collect{ |r| r.id }.include? s.region_id
      s.volunteer = current_volunteer
      s.save
      flash[:notice] = "Successfully took 1 shift."
    else
      flash[:notice] = "Cannot take that pickup since you are not a member of that region."
    end
    open
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.super_admin? or current_volunteer.region_admin?
  end

end 
