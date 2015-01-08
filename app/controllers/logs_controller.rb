class LogsController < ApplicationController
  before_filter :authenticate_volunteer!, :except => :stats_service
  before_filter :admin_only, :only => [:today,:tomorrow,:yesterday,:being_covered,:tardy,:receipt,:new,:create]

  def mine_past
    index(Log.group_by_schedule(Log.past_for(current_volunteer.id)),"My Past Shifts")
  end
  def mine_upcoming
    index(Log.group_by_schedule(Log.upcoming_for(current_volunteer.id)),"My Upcoming Shifts")
  end
  def open
    index(Log.group_by_schedule(Log.needing_coverage(current_volunteer.region_ids)),"Open Shifts")
  end
  def by_day
    n = params[:n].present? ? params[:n].to_i : 0
    d = Time.zone.today+n
    index(Log.group_by_schedule(Log.where("region_id IN (#{current_volunteer.region_ids.join(",")}) AND \"when\" = '#{d.to_s}'")),"Shifts on #{d.strftime("%A, %B %-d")}")
  end
  def last_ten
    index(Log.group_by_schedule(Log.where("region_id IN (#{current_volunteer.region_ids.join(",")}) AND \"when\" >= '#{(Time.zone.today-10).to_s}'")),"Last 10 Days of Shifts")
  end
  def being_covered
    index(Log.group_by_schedule(Log.being_covered(current_volunteer.region_ids)),"Being Covered")
  end
  def todo
    index(Log.group_by_schedule(Log.past_for(current_volunteer.id).where("\"when\" < current_date AND NOT complete")),"My To Do Shift Reports")
  end
  def tardy
    index(Log.group_by_schedule(Log.where("region_id IN (#{current_volunteer.region_ids.join(",")}) AND \"when\" < current_date AND NOT complete and num_reminders >= 3","Missing Data (>= 3 Reminders)")),"Missing Data (>= 3 Reminders)")
  end

  def index(shifts=nil,header="Entire Log")
    filter = filter.nil? ? "" : " AND #{filter}"
    @shifts = []
    if current_volunteer.region_ids.length > 0
      @shifts = shifts.nil? ? Log.group_by_schedule(Log.where("region_id IN (#{current_volunteer.region_ids.join(",")})")) : shifts
    end
    @header = header
    @regions = Region.all
    if current_volunteer.super_admin?
      @my_admin_regions = @regions
    else
      @my_admin_regions = current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
    end
    respond_to do |format|
      format.json { render json: @shifts }
      format.html { render :index }
    end
  end

  def stats_service
    case params[:what]
    when 'poundage'
      if params[:region_id].nil?
        t = LogPart.sum(:weight) + Region.where("prior_lbs_rescued IS NOT NULL").sum("prior_lbs_rescued")
      else
        r = params[:region_id]
        @region = Region.find(r)
        t = Log.joins(:log_parts).where("region_id = ? AND complete",r).sum("weight").to_f
        t += @region.prior_lbs_rescued.to_f unless @region.nil? or @region.prior_lbs_rescued.nil?
      end
      render :text => t.to_s
    when 'wordcloud'
      words = {}
      LogPart.select("description").where("description IS NOT NULL").each{ |l|
        l.description.strip.split(/\s*\,\s*/).each{ |w|
          w = w.strip.downcase.tr(',','')
          next if w =~ /(nothing|no |none)/ or w =~ /etc/ or w =~ /n\/a/ or w =~ /misc/
          # people cannot seem to spell the most delicious fruit correctly
          w = "avocados" if w == "avacados" or w == "avocadoes" or w == "avocado"
          words[w] = 0 if words[w].nil?
          words[w] += 1
        }
      }
      render :text => words.collect{ |k,v| (v >= 10) ? "#{k}:#{v}" : nil }.compact.join(",")
    when 'transport'
      rq = ""
      wq = ""
      unless params[:region_id].nil?
        rq = "AND region_id=#{params[:region_id].to_i}"
      end
      unless params[:timespan].nil?
        if params[:timespan] == "month"
          wq = "AND \"when\" > NOW() - interval '1 month'"
        end
      end
      noncar = Log.where("complete AND transport_type_id IN (SELECT id FROM transport_types WHERE name != 'Car') #{rq} #{wq}").count.to_f
      car = Log.where("complete AND transport_type_id IN (SELECT id FROM transport_types WHERE name = 'Car') #{rq} #{wq}").count.to_f
      render :text => "#{100.0*noncar/(noncar+car)} #{100.0*car/(noncar+car)}"
    else
      render :text => "NO"
    end
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
    @log.region = @region
    @action = "create"
    session[:my_return_to] = request.referer
    set_vars_for_form @region
    render :new
  end

  def create
    @log = Log.new(params[:log])
    if @log.region.scale_types.length<2 and @log.scale_type_id.nil?
      @log.scale_type_id = @log.region.scale_types.first.id
    end
    unless current_volunteer.any_admin? @log.region
      flash[:error] = "Not authorized to create logs for that region"
      redirect_to(root_path)
      return
    end
    if @log.save
      # mark as complete if deserving
      unfilled_count = 0
      params["log_parts"].each{ |dc,lpdata|	
        unless lpdata["food_type_id"].nil?
      	  lp = LogPart.new
          lp.weight = lpdata["weight"]
          lp.count = lpdata["count"]
          unfilled_count += 1 if lp.weight.nil? and lp.count.nil?
          lp.description = lpdata["description"]
          lp.food_type_id = lpdata["food_type_id"].to_i
	  lp.log_id = @log.id
	  lp.save
	end
      } unless params["log_parts"].nil?
      if unfilled_count == 0
        @log.complete = true
        @log.save
      else
	      @log.log_parts.each{ |part|
	        if part.food_type_id.nil? and part.weight.nil? and part.count.nil?
	          part.destroy
	          unfilled_count-=1;
	        end
	      }
	      if unfilled_count == 0
	        @log.complete = true
	        @log.save
	      end
      end

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

  def show
    @log = Log.find(params[:id])
    respond_to do |format|
      format.json {
        attrs = {}
        attrs[:log] = @log.attributes
        attrs[:log][:recipient_ids] = @log.recipient_ids
        attrs[:log][:volunteer_ids] = @log.volunteer_ids
	attrs[:log][:volunteer_names] = @log.volunteers.collect{ |v| v.name }
        attrs[:schedule] = @log.schedule_chain.attributes unless @log.schedule_chain.nil?
        attrs[:log_parts] = {}
        @log.log_parts.each{ |lp| attrs[:log_parts][lp.id] = lp.attributes }
        render json: attrs
      }
    end
  end

  def edit
    @log = Log.find(params[:id])
    unless current_volunteer.any_admin? @log.region or @log.volunteers.include? current_volunteer
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
    @region = @log.region
    @action = "update"
    set_vars_for_form @region

    unless current_volunteer.any_admin? @log.region or @log.volunteers.include? current_volunteer
      flash[:notice] = "Not authorized to edit that log item."
      respond_to do |format|
        format.json { render json: {:error => 1, :message => flash[:notice] } }
        format.html { redirect_to(root_path) }
      end
      return
    end

    params["log_parts"].each{ |dc,lpdata|
      lpdata["weight"] = nil if lpdata["weight"].strip == ""
      lpdata["count"] = nil if lpdata["count"].strip == ""
      next if lpdata["id"].nil? and lpdata["weight"].nil? and lpdata["count"].nil?
      lp = lpdata["id"].nil? ? LogPart.new : LogPart.find(lpdata[:id].to_i)
      lp.count = lpdata["count"]
      lp.description = lpdata["description"]
      lp.food_type_id = lpdata["food_type_id"].to_i
      lp.weight = lpdata["weight"]
      lp.log_id = @log.id
      lp.save
    } unless params["log_parts"].nil?
    if @log.update_attributes(params[:log])
      # mark as complete if deserving
      filled_count = 0
      required_unfilled = 0
      @log.log_parts.each{ |lp|
        required_unfilled += 1 if lp.required and lp.weight.nil? and lp.count.nil?
        filled_count += 1 unless lp.weight.nil? and lp.count.nil?
      }
      @log.complete = filled_count > 0 and required_unfilled == 0
      if @log.save
        if @log.complete
          flash[:notice] = "Updated Successfully. All done!"
        else
          flash[:warning] = "Saved, but some weights/counts still needed to complete this log. Finish it here: <a href=\"/logs/#{@log.id}/edit\">(Fill In)</a>"
        end

        # could be nil if they clicked on the link in an email
        respond_to do |format|
          format.json { render json: {:error => 0, :message => flash[:notice] } }
          format.html {
            redirect_to(home_volunteers_path)
          }
        end
      else
        flash[:notice] = "Failed to mark as complete."
        respond_to do |format|
          format.json { render json: {:error => 2, :message => flash[:notice] } }
          format.html { render :edit }
        end
      end
    else
      flash[:notice] = "Update failed :("
      respond_to do |format|
        format.json { render json: {:error => 1, :message => flash[:notice] } }
        format.html { render :edit }
      end
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
    adminrids = current_volunteer.admin_region_ids

    unless volunteer.id == current_volunteer.id or current_volunteer.super_admin? or (vrids & adminrids).length > 0
      flash[:notice] = "Cannot schedule an absence for that person, mmmmk."
      redirect_to(root_path)
      return
    end

    n = 0
    while from <= to
      n += FoodRobot::generate_log_entries(from,volunteer)
      break if n >= 12      
      from += 1
    end
    if n == 0
      flash[:notice] = nil
      flash[:warning] = "No shift of yours was found in that timeframe, so I couldn't schedule an absense. If you think this is an error, please contact the volunteer coordinator to ensure your absense is scheduled properly. Thanks!"
    else
      flash[:warning] = nil
      flash[:notice] = "Thanks for scheduling an absence, if you would like to pick one up to replace it go here: <a href=\"/logs/open\">cover shifts list</a>.<br><br>#{n} new absences were scheduled (12 is the max at one time)."
    end
    render :new_absence
  end

  # can be given a single id or a list of ids
  def take
    unless params[:ids].present?
      l = [Log.find(params[:id])]
    else
      l = params[:ids].collect{ |i| Log.find(i) }
    end
    if l.all?{ |x| current_volunteer.regions.collect{ |r| r.id }.include? x.region_id }
      l.each{ |x|
        x.volunteers << current_volunteer
        x.save
      }
      flash[:notice] = "Successfully took a shift with #{l.length} donor(s)."
    else
      flash[:notice] = "Cannot take shifts for regions that you aren't assigned to!"
    end
    respond_to do |format|
      format.json {
        render json: {error: 0, message: flash[:notice]}
      }
      format.html {
        redirect_to :back
      }
    end
  end

  # can be given a single id or a list of ids
  def leave
    unless params[:ids].present?
      l = [Log.find(params[:id])]
    else
      l = params[:ids].collect{ |i| Log.find(i) }
    end
    if l.all?{ |x| current_volunteer.in_region? x.region_id }
      l.each do |x|
        if x.has_volunteer? current_volunteer
          LogVolunteer.where(:volunteer_id=>current_volunteer.id, :log_id=>x.id).each{ |lv|
            lv.active = false
            lv.save
          }
        end
      end
      flash[:notice] = "You left a pickup with #{l.length} donor(s)."
    else
      flash[:error] = "Cannot leave that pickup since you are not a member of that region!"
    end
    redirect_to :back
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

    @logs = Log.at(@loc).where("logs.when >= ? AND logs.when <= ?",@start_date,@stop_date)
    respond_to do |format|
      format.html
      format.pdf do
        pdf = Prawn::Document.new
        pdf.font_size 20
        pdf.text @loc.region.title, :align => :center
        unless @loc.region.tagline.nil?
          pdf.move_down 10
          pdf.font_size 12
          pdf.text @loc.region.tagline, :align => :center
        end
        unless @loc.region.address.nil?
          pdf.font_size 10
          pdf.font "Times-Roman"
          pdf.move_down 10
          pdf.text "#{@loc.region.address.tr("\n",", ")}", :align => :center
        end
        unless @loc.region.website.nil?
          pdf.move_down 5 
          pdf.text "#{@loc.region.website}", :align => :center
        end
        unless @loc.region.phone.nil?
          pdf.move_down 5 
          pdf.text "#{@loc.region.phone}", :align => :center
        end
        pdf.move_down 10
        pdf.text "Federal Tax-ID: #{@loc.region.tax_id}", :align => :right
        pdf.text "Receipt period: #{@start_date} to #{@stop_date}", :align => :left
        pdf.move_down 5
        pdf.text "Receipt for: #{@loc.name}", :align => :center
        pdf.move_down 10
        pdf.font "Helvetica"
        sum = 0.0
        pdf.table([["Date","Description","Log #","Weight (lbs)"]] + @logs.collect{ |l|
          sum += l.summed_weight
          [l.when,l.log_parts.collect{ |lp| lp.food_type.nil? ? nil : lp.food_type.name }.compact.join(","),l.id,l.summed_weight] 
        }.compact + [["Total:","","",sum]])
        pdf.move_down 20
        pdf.font_size 10
        pdf.font "Courier", :style => :italic
        pdf.text "This receipt was generated by The Food Rescue Robot at #{Time.zone.now.to_s}. Beep beep mrrrp!", :align => :center
        send_data pdf.render
      end
    end
  end

  private

    def admin_only
      redirect_to(root_path) unless current_volunteer.any_admin?
    end

end
