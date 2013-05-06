class LogsController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only, :only => [:today,:tomorrow,:yesterday,:being_covered,:tardy,:receipt,:new,:create]

  def mine_past
    index("volunteer_id = #{current_volunteer.id} AND \"when\" < current_date","My Past Shifts")
  end
  def mine_upcoming
    index("volunteer_id = #{current_volunteer.id} AND \"when\" >= current_date","My Upcoming Shifts")
  end
  def open
    index("volunteer_id IS NULL AND \"when\" >= current_date","Open Shifts")
  end
  def today
    index("\"when\" = '#{Date.today.to_s}'","Today's Shifts")
  end
  def tomorrow
    index("\"when\" = '#{(Date.today+1).to_s}'","Tomorrow's Shifts")
  end
  def yesterday
    index("\"when\" = '#{(Date.today-1).to_s}'","Yesterday's Shifts")
  end
  def last_ten
    index("\"when\" >= '#{(Date.today-10).to_s}'","Last 10 Days of Shifts")
  end
  def being_covered
    index("\"when\" >= current_date AND orig_volunteer_id IS NOT NULL AND orig_volunteer_id != volunteer_id","Shifts Being Covered")
  end
  def tardy
    index("\"when\" < current_date AND weight IS NULL and num_reminders >= 3","Missing Data (>= 3 Reminders)")
  end

  def index(filter=nil,header="Entire Log")
    filter = filter.nil? ? "" : " AND #{filter}"
    @shifts = []
    @shifts = Log.where("region_id IN (#{current_volunteer.region_ids.join(",")})#{filter}") if current_volunteer.region_ids.length > 0
    @header = header
    @regions = Region.all
    if current_volunteer.super_admin?
      @my_admin_regions = @regions
    else
      @my_admin_regions = current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
    end
    render :index
  end

  def stats
    if current_volunteer.super_admin?
      @regions = Region.all
    else
      @regions = current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
    end
    render :stats
  end

  def destroy
    @l = Log.find(params[:id])
    unless current_volunteer.any_admin? @l.region
      flash[:notice] = "Not authorized to delete log items for that region"
      redirect_to(root_path)
      return
    end
    @l.destroy
    redirect_to(request.referrer)
  end

  def new
    @region = Region.find(params[:region_id])
    unless current_volunteer.any_admin? @region
      flash[:notice] = "Not authorized to create schedule items for that region"
      redirect_to(root_path)
      return
    end
    @log = Log.new
    @action = "create"
    session[:my_return_to] = request.referer
    set_vars_for_form @region
    render :new
  end

  def create
    @log = Log.new(params[:log])
    unless current_volunteer.any_admin? @log.region
      flash[:notice] = "Not authorized to create schedule items for that region"
      redirect_to(root_path)
      return
    end
    if @log.save
      flash[:notice] = "Created successfully."
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:notice] = "Didn't save successfully :("
      render :new
    end
  end

  def edit
    @log = Log.find(params[:id])
    unless current_volunteer.any_admin? @log.region or @log.volunteer == current_volunteer
      flash[:notice] = "Not authorized to edit that log item."
      redirect_to(root_path)
      return
    end
    @region = @log.region
    @action = "update"
    session[:my_return_to] = request.referer
    set_vars_for_form @region
    render :edit
  end

  def update
    @log = Log.find(params[:id])
    unless current_volunteer.any_admin? @log.region or @log.volunteer == current_volunteer
      flash[:notice] = "Not authorized to edit that log item."
      redirect_to(root_path)
      return
    end
    if @log.update_attributes(params[:log])
      flash[:notice] = "Updated Successfully."
      # could be nil if they clicked on the link in an email
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        mine_past
      end
    else
      flash[:notice] = "Update failed :("
      render :edit
    end
  end

  def new_absence
    respond_to do |format|
      format.html # new_absence.html.erb
    end
  end
 
  def create_absence
    from = Date.new(params[:start_date][:year].to_i,params[:start_date][:month].to_i,params[:start_date][:day].to_i)
    to = Date.new(params[:stop_date][:year].to_i,params[:stop_date][:month].to_i,params[:stop_date][:day].to_i)
    volunteer = (params[:volunteer_id].nil?) ? current_volunteer : Volunteer.find(params[:volunteer_id].to_i)
    vrids = volunteer.regions.collect{ |r| r.id }
    adminrids = current_volunteer.assignments.collect{ |a| a.admin ? a.region.id : nil }.compact

    unless volunteer.id == current_volunteer.id or current_volunteer.super_admin? or (vrids & adminrids).length > 0
      flash[:notice] = "Cannot schedule an absence for that person, mmmmk."
      redirect_to(root_path)
      return
    end

    if current_volunteer.admin and !params[:volunteer_id].nil?
      pickups = Schedule.where("volunteer_id = #{params[:volunteer_id].to_i}")
    else
      pickups = Schedule.where("volunteer_id = #{current_volunteer.id}")
    end
    
    n = 0
    while from <= to
      pickups.each{ |p|
        if from.wday.to_i == p.day_of_week.to_i
          p.food_types.each{ |ft|
            # make sure we don't create more than one for the same absence
            found = Log.where('"when" = ? AND schedule_id = ? AND food_type_id = ?',from,p.id,ft.id)
            next if found.length > 0

            # create the null record
            lo = Log.new
            if current_volunteer.admin and !params[:volunteer_id].nil?
              lo.orig_volunteer = Volunteer.find(params[:volunteer_id].to_i)
            else
              lo.orig_volunteer = current_volunteer
            end
            lo.volunteer = nil
            lo.schedule = p
            lo.donor = p.donor
            lo.recipient = p.recipient
            lo.when = from
            lo.food_type = ft
            lo.region = p.region
            lo.save
          }
          n += 1
        end
      }
      break if n >= 12      
      from += 1
    end
    flash[:notice] = "Scheduled #{n} absences (12 is the max at one time)"
    render :new_absence
  end

  def take
    l = Log.find(params[:id])
    if current_volunteer.regions.collect{ |r| r.id }.include? l.region_id
      l.volunteer = current_volunteer
      l.save
      flash[:notice] = "Successfully took one shift."
    else
      flash[:notice] = "Cannot take shifts for regions that you aren't assigned to!"
    end
    open
  end

  def receipt
    @start_date = Date.new(params[:start_date][:year].to_i,params[:start_date][:month].to_i,params[:start_date][:day].to_i)
    @stop_date = Date.new(params[:stop_date][:year].to_i,params[:stop_date][:month].to_i,params[:stop_date][:day].to_i)
    @loc = Location.find(params[:location_id])
    unless current_volunteer.any_admin?(@loc.region)  
      flash[:notice] = "Cannot generate receipt for donors/receipients in other regions than your own!"
      redirect_to(root_path)
      return
    end
    @logs = Log.where("#{@loc.is_donor ? "donor_id" : "recipient_id"} = ? AND \"when\" >= ? AND \"when\" <= ?",@loc.id,@start_date,@stop_date)
    respond_to do |format|
      format.html
      format.pdf do
        pdf = Prawn::Document.new
        pdf.font_size 20
        pdf.text @loc.region.title, :align => :center
        pdf.move_down 10
        pdf.font_size 12
        pdf.text @loc.region.tagline, :align => :center
        pdf.font_size 10
        pdf.font "Times-Roman"
        pdf.move_down 10
        pdf.text "#{@loc.region.address.tr("\n",", ")}", :align => :center
        pdf.move_down 5 
        pdf.text "#{@loc.region.website}", :align => :center
        pdf.move_down 5 
        pdf.text "#{@loc.region.phone}", :align => :center
        pdf.move_down 10
        pdf.text "Federal Tax-ID: #{@loc.region.tax_id}", :align => :right
        pdf.text "Receipt period: #{@start_date} to #{@stop_date}", :align => :left
        pdf.move_down 5
        pdf.text "Receipt for: #{@loc.name}", :align => :center
        pdf.move_down 10
        pdf.font "Helvetica"
        sum = 0.0
        pdf.table([["Date","Description","Log #","Weight (lbs)"]] + @logs.collect{ |l|
          sum += l.weight unless l.weight.nil?
          (l.weight == 0.0 or l.weight.nil?) ? nil : [l.when,l.description,l.id,l.weight] 
        }.compact + [["Total:","","",sum]])
        pdf.move_down 20
        pdf.font_size 10
        pdf.font "Courier", :style => :italic
        pdf.text "This receipt was generated by The Food Rescue Robot at #{Time.now.to_s}. Beep beep mrrrp!", :align => :center
        send_data pdf.render
      end
    end
  end

  private

    def admin_only
      redirect_to(root_path) unless current_volunteer.any_admin?
    end

end
