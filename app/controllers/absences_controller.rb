class AbsencesController < ApplicationController
  before_filter :authenticate_volunteer!

  def mine
    index(current_volunteer.absences,"Your Absences")
  end

  def index(absences=nil,header=nil)
    @absences = absences.nil? ? Absence.all : absences
    @header = header.nil? ? "Absences" : header
    respond_to do |format|
      format.html # index.html.erb
    end
  end

  def new
    @absence = Absence.new
    respond_to do |format|
      format.html # new.html.erb
    end
  end

  def create
    @absence = Absence.new(params[:absence])
    #from = Date.new(params[:start_date][:year].to_i,params[:start_date][:month].to_i,params[:start_date][:day].to_i)
    #to = Date.new(params[:stop_date][:year].to_i,params[:stop_date][:month].to_i,params[:stop_date][:day].to_i)
    #volunteer = (params[:volunteer_id].nil?) ? current_volunteer : Volunteer.find(params[:volunteer_id].to_i)
    volunteer = @absence.volunteer
    vrids = volunteer.regions.collect{ |r| r.id }
    adminrids = current_volunteer.admin_region_ids

    unless volunteer.id == current_volunteer.id or current_volunteer.super_admin? or (vrids & adminrids).length > 0
      flash[:notice] = "Cannot schedule an absence for that person, mmmmk."
      redirect_to(root_path)
      return
    end

    if @absence.save
      from = @absence.start_date
      to = @absence.stop_date
      n = 0
      while from <= to
        n += FoodRobot::generate_log_entries(from,@absence.dup)
        break if n >= 12
        from += 1
      end
      if n == 0
        flash[:notice] = nil
        flash[:warning] = "No shift of yours was found in that timeframe, so I couldn't schedule an absense. If you think this is an error, please contact the volunteer coordinator to ensure your absense is scheduled properly. Thanks!"
        render :new
      else
        flash[:warning] = nil
        flash[:notice] = "Thanks for scheduling an absence, if you would like to pick one up to replace it go here: <a href=\"/logs/open\">cover shifts list</a>.<br><br>#{n} new absences were scheduled (12 is the max at one time)."
        render :new
      end
    else
      flash[:warning] = "Didn't save successfully :("
      render :new
    end
  end

end
