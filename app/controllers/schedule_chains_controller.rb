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

  def index(title = 'Full Schedule', day_of_week = nil)
    if day_of_week.nil?
      dowq = ' '
    else
      dowq = "day_of_week = #{day_of_week.to_i}"
    end
    @schedules = ScheduleChain.where(region_id: current_volunteer.region_ids).where(dowq)
    @my_admin_regions = current_volunteer.admin_regions
    @page_title = title
    render :index
  end

  def show
    @schedule = ScheduleChain.find(params[:id])
    schedules = @schedule.schedules

    # prep the google maps embed request
    api_key = 'AIzaSyD8c6OCF67BCrCMbgBNrcdEEuDnCNqWlk4'
    embed_parameters = ''
    f_l_scheds = [schedules.first, schedules.last]
    trimmed_stops = schedules.select { |stop| !(f_l_scheds.include? stop) }

    unless schedules.empty? || schedules.first.location.nil?
      sched = schedules.first
      embed_parameters += '&origin=' + sched.location.address.tr(' ', '+').gsub(/\r\n?/, "")
    end

    unless schedules.empty? || schedules.last.location.nil?
      addr = schedules.last.location.address
      embed_parameters += '&destination=' + addr.tr(' ', '+').gsub(/\r\n?/, "")
    end

    unless trimmed_stops.empty?
      embed_parameters += '&waypoints='
      trimmed_stops.each do |stop|
        embed_parameters += stop.location.address.tr(' ', '+').gsub(/\r\n?/, "")
        embed_parameters += '|' unless stop == trimmed_stops.last
      end
    end


    embed_parameters += '&mode=bicycling'
    @embed_request_url = ('https://www.google.com/maps/embed/v1/directions' + '?key=' + api_key + embed_parameters)

    #This can apparently be nil, so have to do a funky sort fix
    @sorted_related_shifts = @schedule.related_shifts.sort{ |x,y|
      x.schedule_chain.day_of_week && y.schedule_chain.day_of_week ?
        x.schedule_chain.day_of_week <=> y.schedule_chain.day_of_week : x.schedule_chain.day_of_week ? -1 : 1
    }

    if params[:nolayout].present? && params[:nolayout].to_i == 1
      render(:show, layout: false)
    else
      render :show
    end
  end

  def today
    index("Today's Schedule", Time.zone.today.wday)
  end

  def tomorrow
    day_of_week = Time.zone.today.wday + 1
    day_of_week = 0 if day_of_week > 6
    index("Tomorrow's Schedule", day_of_week)
  end

  def yesterday
    day_of_week = Time.zone.today.wday - 1
    day_of_week = 6 if day_of_week < 0
    index("Yesterday's Schedule", day_of_week)
  end

  def destroy
    @s = ScheduleChain.find(params[:id])
    unless current_volunteer.any_admin? @s.region
      flash[:error] = "Not authorized to delete schedule items for that region"
      redirect_to(root_path)
      return
    end
    @s.active = false
    @s.save
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
    delete_schedules = []
    params[:schedule_chain]["schedules_attributes"].collect{ |k,v|
      delete_schedules << v["id"].to_i if v["food_type_ids"].nil?
    } unless params[:schedule_chain]["schedules_attributes"].nil?
    delete_volunteers = []
    params[:schedule_chain]["schedule_volunteers_attributes"].collect{ |k,v|
      delete_volunteers << v["id"].to_i if v["volunteer_id"].nil?
    } unless params[:schedule_chain]["schedule_volunteers_attributes"].nil?
    if @schedule.update_attributes(params[:schedule_chain])
      @schedule.schedules.each{ |s|
        s.delete if delete_schedules.include? s.id
      }
      @schedule.schedule_volunteers.each{ |s|
        s.update_attributes({active: false}) if delete_volunteers.include? s.id
      }
      flash[:notice] = "Updated Successfully"
      index
    else
      flash[:error] = "Update failed :("
      render :edit
    end
  end

  def leave
    schedule_chain = ScheduleChain.find(params[:id])

    if current_volunteer.in_region? schedule_chain.region_id
      if schedule_chain.has_volunteer? current_volunteer
        volunteers = ScheduleVolunteer.where(volunteer_id: current_volunteer.id, schedule_chain_id: schedule_chain.id)
        volunteers.each{ |sv| sv.update_attributes({active: false}) }
        flash[:notice] = "You are no longer on the route ending at #{schedule_chain.from_to_name}."
      else
        flash[:error] = "Cannot leave route since you're not part of it!"
      end
    else
      flash[:error] = "Cannot leave that route since you are not a member of that region!"
    end
    redirect_to action: 'show', id: schedule_chain.id
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
          Log.where('schedule_chain_id = ? AND "when" >= current_date AND NOT complete',schedule.id).each{ |l|
            if l.volunteers.empty?
              l.volunteers << current_volunteer
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
    respond_to do |format|
      format.json {
        render json: {error: flash[:error].empty?, message: (flash[:notice] or flash[:error])}
      }
      format.html {
        redirect_to :action=>'show', :id=>schedule.id
      }
    end
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.any_admin?
  end

end
