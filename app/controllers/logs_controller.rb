class LogsController < ApplicationController
  before_filter :authenticate_volunteer!, :except => :stats_service
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
    index("\"when\" = '#{Time.zone.today.to_s}'","Today's Shifts")
  end
  def tomorrow
    index("\"when\" = '#{(Time.zone.today+1).to_s}'","Tomorrow's Shifts")
  end
  def yesterday
    index("\"when\" = '#{(Time.zone.today-1).to_s}'","Yesterday's Shifts")
  end
  def last_ten
    index("\"when\" >= '#{(Time.zone.today-10).to_s}'","Last 10 Days of Shifts")
  end
  def being_covered
    index("\"when\" >= current_date AND orig_volunteer_id IS NOT NULL AND orig_volunteer_id != volunteer_id","Shifts Being Covered")
  end
  def tardy
    index("\"when\" < current_date AND NOT complete and num_reminders >= 3","Missing Data (>= 3 Reminders)")
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

  def stats_service
    case params[:what]
    when 'poundage'
      if params[:region_id].nil?
        t = LogPart.sum(:weight).to_i + Region.where("prior_lbs_rescued IS NOT NULL").sum("prior_lbs_rescued")
      else
        r = params[:region_id]
        @region = Region.find(r)
        t = Log.joins(:log_parts).where("region_id = ? AND complete",r).sum("weight").to_i
        t += @region.prior_lbs_rescued unless @region.nil? or @region.prior_lbs_rescued.nil?
      end
      render :text => t.to_s
    when 'wordcloud'
      words = {}
      LogPart.select("description").where("description IS NOT NULL").each{ |l|
        l.description.strip.split(/\s*\,\s*/).each{ |w|
          w = w.strip.downcase.tr(',','')
          next if w =~ /(nothing|no |none)/ or w =~ /etc/ or w =~ /n\/a/ or w =~ /misc/
          # people cannot seem to spell the most delicious fruit correctly
          w = "avocados" if w == "avacados" or w == "avocadoes" or w == "avocado" or w == "proto-guacamole"
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
    unless current_volunteer.any_admin? @log.region
      flash[:notice] = "Not authorized to create schedule items for that region"
      redirect_to(root_path)
      return
    end
    if @log.save

      # mark as complete if deserving
      unfilled_count = 0
      params["log_parts"].each{ |dc,lpdata|	
        unless lpdata["food_type_id"].nil?
	  lp = LogPart.new
          base_weight = lpdata["weight"]
          lp.count = lpdata["count"]
          unfilled_count += 1 if lp.weight.nil? and lp.count.nil?
          lp.description = lpdata["description"]
          lp.food_type_id = lpdata["food_type_id"].to_i
	  scale = ScaleType.where('id = ?',@log.scale_type_ids.first)
	  weight_unit = scale.first.weight_unit
	  conv_weight = base_weight.to_f
	  conv_weight = (conv_weight * (1/2.2).to_f) if weight_unit == "kg"
  	  conv_weight = (conv_weight * (1/14).to_f) if weight_unit == "st"
	  lp.weight = conv_weight.to_i
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
    @region = @log.region
    @action = "update"
    set_vars_for_form @region

    unless current_volunteer.any_admin? @log.region or @log.volunteer == current_volunteer
      flash[:notice] = "Not authorized to edit that log item."
      redirect_to(root_path)
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
       flash[:notice] = "Updated Successfully. " + (@log.complete ? " (Filled)" : " (Still To Do)")
        # could be nil if they clicked on the link in an email
        unless session[:my_return_to].nil?
          redirect_to(session[:my_return_to])
        else
          mine_past
        end
      else
        flash[:notice] = "Failed to mark as complete."
        render :edit
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
    nexisting = 0
    while from <= to
      pickups.each{ |p|
        next unless from.wday.to_i == p.day_of_week.to_i
        # make sure we don't create more than one for the same absence
        found = Log.where('"when" = ? AND schedule_id = ?',from,p.id)
        if found.length > 0
          nexisting += 1
          next
        end

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
        lo.food_types = p.food_types
        lo.scale_types = p.scale_types
        lo.region = p.region
        lo.save
        n += 1
      }
      break if n >= 12      
      from += 1
    end
    flash[:notice] = "Thanks for scheduling an absence, if you would like to pick one up to replace it go here: <a href=\"/logs/open\">cover shifts list</a>.<br><br>#{nexisting} absences were already scheduled during this time frame, #{n} new absences were scheduled (12 is the max at one time)."
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
