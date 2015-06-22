class AbsencesController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only, :only => [:all]

  def all
    absences = Absence.where("stop_date >= ?",Date.today).keep_if{ |a|
      (a.volunteer.region_ids & current_volunteer.admin_region_ids).length > 0
    }
    index(absences,"All Absences")
  end

  def index(a=nil,header="Absences")
    @absences = a.nil? ? Absence.where("stop_date >= ? AND volunteer_id=?",Date.today,current_volunteer.id) : a
    @header = header.nil? ? "Absences" : header
    respond_to do |format|
      format.html { render :index } # index.html.erb
    end
  end

  def new
    @absence = Absence.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def destroy
    @absence = Absence.find(params[:id])
    skip_count = 0
    take_count = 0
    irrelevant_count = 0
    @absence.logs.each{ |l|
      if l.covering_volunteers.empty?
        # can take back, no one is covering it
        # take back, but only if we're still assigned to the associated schedule
        if not l.schedule_chain.nil? and l.schedule_chain.volunteers.include? @absence.volunteer
          l.volunteers << @absence.volunteer
          # if it's sufficiently far in the future and seems unmodified, delete it anyway
          if l.volunteers.uniq == l.schedule_chain.volunteers.uniq and l.when > Date.today+3
            l.destroy
            irrelevant_count += 1
          else
            l.save
            take_count += 1
          end
        else
          # if we're no longer assigned to the schedule, and it isn't being covered, just destroy it
          l.destroy
          irrelevant_count += 1
        end
      else
        # cannot take back
        skip_count += 1
      end
    }
    @absence.active = false
    @absence.save
    flash[:notice] = "The absence has been cancelled and #{take_count} shifts have been reclaimed by the original volunteer. BEWARE: #{skip_count} shifts had been already claimed by another volunteer and will be left as they are, and #{irrelevant_count} unclaimed future shifts were cleaned up since they are now irrelevant."
    redirect_to :back
  end

  def create
    @absence = Absence.new(params[:absence])
    @absence.volunteer ||= current_volunteer
    volunteer = @absence.volunteer
    vrids = volunteer.regions.collect{ |r| r.id }
    adminrids = current_volunteer.admin_region_ids

    unless volunteer.id == current_volunteer.id or current_volunteer.super_admin? or (vrids & adminrids).length > 0
      flash[:notice] = "Cannot schedule an absence for that person, mmmmk."
      redirect_to(root_path)
      return
    end

    from = @absence.start_date
    to = @absence.stop_date
    n = 0
    ns = 0
    while from <= to
      (n_did,n_skipped) = FoodRobot::generate_log_entries(from,@absence)
      n += n_did
      ns += n_skipped
      break if n >= 12
      from += 1
    end
    if (n+ns) == 0
      flash[:notice] = nil
      flash[:warning] = "No shifts of yours was found in that timeframe, so I couldn't schedule an absence. If you think this is an error, please contact the volunteer coordinator to ensure your absence is scheduled properly. Thanks!"
      render :new
    else
      if @absence.save
        flash[:warning] = nil
        flash[:notice] = "Thanks for scheduling an absence, if you would like to pick one up to replace it go here: <a href=\"#{open_logs_path}\">cover shifts list</a>.<br><br>#{n+ns} shifts will be skipped (12 is the max at one time, #{ns} were already present). You can see your scheduled absences <a href=\"#{absences_path}\">here</a>."
        render :new
      else
        flash[:warning] = "Didn't save successfully :("
        render :new
      end
    end
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.any_admin?
  end

end
