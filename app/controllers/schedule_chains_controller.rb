class ScheduleChainsController < ApplicationController
	before_filter :authenticate_volunteer!
	before_filter :admin_only, :only => [:fast_schedule, :today, :tomorrow, :yesterday, :edit, :update, :create, :new]

	def open
		@schedules = ScheduleChain.open_in_regions current_volunteer.region_ids
		@my_admin_regions = current_volunteer.admin_regions
		@page_title = "Open Shifts"
		render :index
	end

	def mine
		@schedules = current_volunteer.schedule_chains
		@my_admin_regions = current_volunteer.admin_regions
		@page_title = "My Regular Shifts"
		render :index
	end

	def index(title='Full Schedule', day_of_week=nil)
		#trinary operator was causing syntax errors
		if day_of_week.nil?
			dowq=""
		else
			dowq="day_of_week = #{day_of_week.to_i}"
		end
		@schedules = ScheduleChain.where(:region_id => current_volunteer.region_ids).where(dowq)
		@my_admin_regions = current_volunteer.admin_regions
		@page_title = title
		render :index
	end

	def show
		@schedule = ScheduleChain.find(params[:id])
		if params[:nolayout].present? and params[:nolayout].to_i == 1
			render(:show,:layout => false)
		else
			render :show
		end
	end

	def today
    index("Today's Schedule",Time.zone.today.wday)
  end
  def tomorrow
    index("Tomorrow's Schedule",Time.zone.today.wday+1 % 6)
  end
  def yesterday
    day_of_week = Time.zone.today.wday - 1
    day_of_week = 6 if day_of_week < 0
    index("Yesterday's Schedule",day_of_week)
  end

	def destroy
    @s = ScheduleChain.find(params[:id])
    unless current_volunteer.any_admin? @s.region
      flash[:error] = "Not authorized to delete schedule items for that region"
      redirect_to(root_path)
      return
    end
    @s.schedules.each do |sch|
      sch.destroy
    end
    @s.destroy
    redirect_to(request.referrer)
  end

	def new
    @region = Region.find(params[:region_id])
    unless current_volunteer.any_admin? @region
      flash[:error] = "Not authorized to create schedule items for that region"
      redirect_to(root_path)
      return
    end
    @schedule = ScheduleChain.new
    @schedule.volunteers.build
    @schedule.region = @region
    set_vars_for_form @region
    @action = "create"
    render :new
  end

	def create
    @schedule = ScheduleChain.new(params[:schedule_chain])
    unless current_volunteer.any_admin? @schedule.region
      flash[:error] = "Not authorized to create schedule items for that region"
      redirect_to(root_path)
      return
    end
    if @schedule.save
      #load schedule items into chain
			params["schedule"].each do |temp, stpdata|
        stp = Schedule.new
        stp.schedule_chain_id=@schedule.id
        stp.location_id=stpdata["location_id"]
        stp.food_type_ids=stpdata["food_type_ids"]
        stp.update_attribute :position_position, :last
        stp.save
        @schedule.schedule_ids << stp.id
      end
			@schedule.schedules.each_with_index do |recipient, r_index|
        unless recipient.is_pickup_stop?
          log = Log.new
          log.volunteers=recipient.schedule_chain.volunteers
				  log.recipient_id = recipient.location.id
          @schedule.schedules.each_with_index do |donor, d_index|
            if donor.is_pickup_stop?
					    if d_index < r_index
						    log.donor_ids << donor.location.id
						    donor.food_type_ids.each do |foodid|
							    log.food_type_ids << foodid
						    end
              end
            end
				  end
				  log.save
        end
      end
      flash[:notice] = "Created successfully"
      index
    else
      flash[:error] = "Didn't save successfully :("
      render :new
    end
  end

	def edit
    @schedule = ScheduleChain.find(params[:id])
    unless current_volunteer.any_admin? @schedule.region
      flash[:error] = "Not authorized to edit schedule items for that region"
      redirect_to(root_path)
      return
    end
    @region = @schedule.region
    set_vars_for_form @region
    @action = "update"
  end

  def update
    @schedule = ScheduleChain.find(params[:id])
    unless current_volunteer.any_admin? @schedule.region
      flash[:error] = "Not authorized to edit schedule items for that region"
      redirect_to(root_path)
      return
    end
    if @schedule.update_attributes(params[:schedule_chain])
      flash[:notice] = "Updated Successfully"
      index
    else
      flash[:error] = "Update failed :("
      render :edit
    end
  end

	def leave
    schedule = ScheduleChain.find(params[:id])
    if current_volunteer.in_region? schedule.region_id
      if schedule.has_volunteer? current_volunteer
        ScheduleVolunteer.where(:volunteer_id=>current_volunteer.id, :schedule_id=>schedule.id).delete_all
        flash[:notice] = "You are no longer on the route ending at "+schedule.schedules.last.name+"."
      else
        flash[:error] = "Cannot leave route since you're not part of it!"
      end
    else
      flash[:error] = "Cannot leave that route since you are not a member of that region!"
    end
    redirect_to :action=>'show', :id=>schedule.id
  end

	def take
    schedule = ScheduleChain.find(params[:id])
    if current_volunteer.in_region? schedule.region_id
      if schedule.has_volunteer? current_volunteer
        flash[:error] = "You are already on this shift"
      else
        schedule_volunteer = ScheduleVolunteer.new(:volunteer_id=>current_volunteer.id, :schedule_chain_id=>schedule.id)
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
          notice = "You have "
          if schedule.volunteers.length == 0
            notice += "taken"
          else
            notice += "joined"
          end
          notice += " the route to "
          if schedule.recipient_stops.length == 1
            notice += (schedule.recipient_stops.first.location.name + ".")
          else
            schedule.recipient_stops.each_with_index do |stop, index|
              if index == (schedule.recipient_stops.length-1)
                notice += ("and " + stop.location.name + ".")
              else
                notice += (stop.location.name + ", ") #oxford comma
              end
            end
          end
          flash[:notice] = notice
       else
          flash[:error] = "Hrmph. That didn't work..."
        end
      end
    else
      flash[:error] = "Cannot take that pickup since you are not a member of that region!"
    end
    redirect_to :action=>'show', :id=>schedule.id
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.any_admin?
  end

end
