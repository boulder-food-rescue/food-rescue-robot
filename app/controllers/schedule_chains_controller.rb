# frozen_string_literal: true

class ScheduleChainsController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only, :only => [:today, :tomorrow, :yesterday]

  def open
    @chains = ScheduleChain.open_in_regions current_volunteer.region_ids
    @my_admin_regions = current_volunteer.admin_regions
    @page_title = 'Open Shifts'
    render :index
  end

  def mine
    @chains = current_volunteer.schedule_chains
    @my_admin_regions = current_volunteer.admin_regions
    @page_title = 'My Regular Shifts'
    render :index
  end

  def index(title = 'Full Schedule', day_of_week = nil)
    dowq = if day_of_week.nil?
             ' '
           else
             "day_of_week = #{day_of_week.to_i}"
           end
    @chains = ScheduleChain.where(region_id: current_volunteer.region_ids).where(dowq)
    @my_admin_regions = current_volunteer.admin_regions
    @page_title = title
    render :index
  end

  def show
    @chain = ScheduleChain.includes(:schedules).find(params[:id])
    schedules = @chain.schedules

    # prep the google maps embed request
    embed_parameters = ''
    first_last_schedules = [schedules.first, schedules.last]
    trimmed_stops = schedules.select { |stop| !first_last_schedules.include?(stop) }

    unless schedules.empty? || schedules.first.location.nil?
      sched = schedules.first
      embed_parameters += '&origin=' + sched.location.mappable_address
    end

    unless schedules.empty? || schedules.last.location.nil?
      addr = schedules.last.location.mappable_address
      embed_parameters += '&destination=' + addr
    end

    unless trimmed_stops.empty?
      stops = trimmed_stops.map { |stop| stop.location&.mappable_address }.compact.join('|')
      embed_parameters = "#{embed_parameters}&waypoints=#{stops}"
    end

    @embed_request_url = "https://www.google.com/maps/embed/v1/directions?key=#{ENV['GMAPS_API_KEY']}#{embed_parameters}&mode=bicycling"

    # This can apparently be nil, so have to do a funky sort fix
    @sorted_related_shifts = @chain.related_shifts.sort{ |x, y|
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
    schedule_chain = ScheduleChain.find(params[:id])
    authorize! :destroy, schedule_chain

    schedule_chain.active = false
    schedule_chain.save

    redirect_to(request.referrer || schedule_chains_path)
  end

  def new
    @region = Region.find(params[:region_id])
    @chain = ScheduleChain.new
    @chain.volunteers.build
    @chain.region = @region
    authorize! :create, @chain

    set_vars_for_form @region
    @action = 'create'
    render :new
  end

  def create
    @chain = ScheduleChain.new(params[:schedule_chain])
    authorize! :create, @chain

    if CreateScheduleChain.call(schedule_chain: @chain).success?
      flash[:notice] = 'Created successfully'
      index
    else
      flash[:error] = "Didn't save successfully :(. #{@chain.errors.full_messages.to_sentence}"
      render :new
    end
  end

  def edit
    @chain = ScheduleChain.find(params[:id])
    authorize! :update, @chain

    @region = @chain.region
    set_vars_for_form @region
    @inactive_volunteers = @chain.schedule_volunteers.select { |sched_vol| sched_vol.active == false }
    @action = 'update'
  end

  def update
    @schedule_chain = ScheduleChain.find(params[:id])
    authorize! :update, @schedule_chain

    delete_schedules = []
    params[:schedule_chain]['schedules_attributes']&.collect{ |_k, v|
      delete_schedules << v['id'].to_i if v['food_type_ids'].nil?
    }

    delete_volunteers = []
    params[:schedule_chain]['schedule_volunteers_attributes']&.collect{ |_k, v|
      delete_volunteers << v['id'].to_i if v['volunteer_id'].nil?
    }

    if @schedule_chain.update_attributes(params[:schedule_chain])
      @schedule_chain.schedules.each do |schedule|
        schedule.delete if delete_schedules.include?(schedule.id)
      end

      @schedule_chain.schedule_volunteers.each do |scheduled_vol|
        next unless delete_volunteers.include?(scheduled_vol.id)
        scheduled_vol.update_attributes({ active: false })
        Log.upcoming_for(scheduled_vol.id).each do |log|
          log.log_volunteers.destroy_all
        end
      end

      flash[:notice] = 'Updated Successfully'
      index
    else
      flash[:error] = "Didn't update successfully :(. #{@schedule_chain.errors.full_messages.to_sentence}"
      render :edit
    end
  end

  def leave
    schedule_chain = ScheduleChain.find(params[:id])

    if current_volunteer.in_region? schedule_chain.region_id
      if schedule_chain.volunteer? current_volunteer
        volunteers = ScheduleVolunteer.where(volunteer_id: current_volunteer.id, schedule_chain_id: schedule_chain.id)
        volunteers.each{ |sv| sv.update_attributes({active: false}) }
        flash[:notice] = "You are no longer on the route ending at #{schedule_chain.from_to_name}."
      else
        flash[:error] = "Cannot leave route since you're not part of it!"
      end
    else
      flash[:error] = 'Cannot leave that route since you are not a member of that region!'
    end
    redirect_to action: 'show', id: schedule_chain.id
  end

  def take
    schedule = ScheduleChain.find(params[:id])
    if current_volunteer.in_region? schedule.region_id
      if schedule.volunteer? current_volunteer
        flash[:error] = 'You are already on this shift'
      else
        schedule_volunteer = ScheduleVolunteer.new(:volunteer_id=>current_volunteer.id, :schedule_chain_id=>schedule.id)
        if schedule_volunteer.save
          collided_shifts = []
          Log.where('schedule_chain_id = ? AND "when" >= current_date AND NOT complete', schedule.id).each{ |l|
            if l.volunteers.empty?
              l.volunteers << current_volunteer
              l.save
            else
              collided_shifts.push(l)
            end
          }
          unless collided_shifts.empty?
            m = Notifier.schedule_collision_warning(schedule, collided_shifts)
            m.deliver
          end
          notice = 'You have '
          notice += if schedule.volunteers.empty?
                      'taken'
                    else
                      'joined'
                    end
          notice += ' the route to '
          if schedule.recipient_stops.length == 1
            notice += (schedule.recipient_stops.first.location.name + '.')
          else
            schedule.recipient_stops.each_with_index do |stop, index|
              notice += if index == (schedule.recipient_stops.length-1)
                          ('and ' + stop.location.name + '.')
                        else
                          (stop.location.name + ', ') # oxford comma
                        end
            end
          end
          flash[:notice] = notice
        else
          flash[:error] = "Hrmph. That didn't work..."
        end
      end
    else
      flash[:error] = 'Cannot take that pickup since you are not a member of that region!'
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
