class SchedulesController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only, :only => [:fast_schedule,:today,:tomorrow,:yesterday,:edit,:update,:create,:new]

  def open
    @schedules = Schedule.open_in_regions current_volunteer.region_ids
    @my_admin_regions = current_volunteer.admin_regions
    render :index
  end

  # TODO: handle volunteer.region_ids==0 case
  def mine
    # schedules where: (I am a volunteer on)
    @schedules = current_volunteer.schedules
    @my_admin_regions = current_volunteer.admin_regions
    render :index
  end

  # TODO: handle volunteer.region_ids==0 case
  def index(day_of_week=nil)
    dowq = day_of_week.nil? ? "" : "day_of_week = #{day_of_week.to_i}"
    @schedules = Schedule.where(:region_id => current_volunteer.region_ids).where(dowq)
    @my_admin_regions = current_volunteer.admin_regions
    render :index
  end

  def show
    @schedule = Schedule.find(params[:id])
    if params[:nolayout].present? and params[:nolayout].to_i == 1
      render(:show,:layout => false)
    else
      render :show
    end
  end

  def today
    index(Time.zone.today.wday)
  end
  def tomorrow
    index(Time.zone.today.wday+1 % 6)
  end
  def yesterday
    day_of_week = Time.zone.today.wday - 1
    day_of_week = 6 if day_of_week < 0
    index(day_of_week)
  end

  def destroy
    @s = Schedule.find(params[:id])
    unless current_volunteer.any_admin? @s.region
      flash[:notice] = "Not authorized to delete schedule items for that region"
      redirect_to(root_path)
      return
    end
    @s.destroy
    redirect_to(request.referrer)
  end

  def new
    @region = Region.find(params[:region_id])
    unless current_volunteer.any_admin? @region
      flash[:notice] = "Not authorized to create schedule items for that region"
      redirect_to(root_path)
      return
    end
    @schedule = Schedule.new
    @schedule.region = @region
    set_vars_for_form @region
    @action = "create"
    render :new
  end

  def create
    @schedule = Schedule.new(params[:schedule])
    unless current_volunteer.any_admin? @schedule.region
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
    unless current_volunteer.any_admin? @schedule.region
      flash[:notice] = "Not authorized to edit schedule items for that region"
      redirect_to(root_path)
      return
    end
    @region = @schedule.region
    set_vars_for_form @region
    @action = "update"
  end

  def update
    @schedule = Schedule.find(params[:id])
    unless current_volunteer.any_admin? @schedule.region
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
    schedule = Schedule.find(params[:id])
    if current_volunteer.in_region? schedule.region_id

      schedule_volunteer = ScheduleVolunteer.new
      schedule_volunteer.volunteer = current_volunteer
      schedule_volunteer.schedule = schedule
      if schedule_volunteer.save
        collided_shifts = []
        Log.where('schedule_id = ? AND "when" >= current_date AND NOT complete',schedule.id).each{ |l|
          if l.volunteer.nil?
            l.volunteer = current_volunteer
            l.save
          else
            collided_shifts.push(l)
          end
        }
        if collided_shifts.length > 0
          m = Notifier.schedule_collision_warning(schedule,collided_shifts)
          m.deliver
        end
        flash[:notice] = "The shift is yours!"
      else
        flash[:notice] = "Hrmph. That didn't work..."
      end
      
    else
      flash[:notice] = "Cannot take that pickup since you are not a member of that region."
    end

    open
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.any_admin?
  end

end 
 