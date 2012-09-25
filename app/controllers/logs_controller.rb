class LogsController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only, :only => [:today,:tomorrow,:yesterday,:being_covered,:tardy,:receipt]

  active_scaffold :log do |conf|
    conf.columns = [:region,:when,:volunteer,:donor,:recipient,:weight,:weighed_by,
                    :description,:transport_type,:food_type,:notes,:flag_for_admin,:num_reminders,:orig_volunteer]
    conf.list.columns = [:when,:volunteer,:donor,:recipient,:weight,:transport_type,:food_type,:orig_volunteer,:schedule]
    conf.list.per_page = 50
    conf.columns[:weighed_by].form_ui = :select
    conf.columns[:weighed_by].options = {:options => [["Bathroom Scale","Bathroom Scale"],["Floor Scale","Floor Scale"],
                                                      ["Guesstimate","Guesstimate"]]}
    conf.columns[:weight].description = "e.g., '42', in pounds. Put a 0 if the pickup didn't happen for some reason or there was no food."
    conf.columns[:num_reminders].form_ui = :select
    conf.columns[:num_reminders].label = "Reminders Sent"
    conf.columns[:num_reminders].options = {:options => [[0,0],[1,1],[2,2],[3,3],[4,4]]}
    conf.columns[:schedule].form_ui = :select
    conf.columns[:region].form_ui = :select
    conf.columns[:volunteer].form_ui = :select
    conf.columns[:volunteer].clear_link
    conf.columns[:food_type].form_ui = :select
    conf.columns[:food_type].clear_link
    conf.columns[:description].description = "e.g., apples, pears, bananas, turnips, swiss chard"
    conf.columns[:volunteer].description = "If someone else covered this shift for you, switch the volunteer to them"
    conf.columns[:transport_type].clear_link
    conf.columns[:transport_type].form_ui = :select
    conf.columns[:orig_volunteer].form_ui = :select
    conf.columns[:orig_volunteer].label = "Original Volunteer"
    conf.columns[:orig_volunteer].description = "If the shift was covered by someone else, put the original volunteer here"
    conf.columns[:orig_volunteer].clear_link
    conf.columns[:notes].description = "e.g., Trailer wheel is out of true, bin is busted, most raddest pickup evar"
    conf.columns[:flag_for_admin].description = "Click this if you'd like to make sure we read your note :)"
    conf.columns[:donor].form_ui = :select
    conf.columns[:donor].clear_link
    conf.columns[:recipient].form_ui = :select
    conf.columns[:recipient].clear_link
    conf.columns[:schedule].clear_link
    conf.update.columns = [:region,:when,:volunteer,:donor,:recipient,:weight,:weighed_by,:description,:transport_type,:food_type,:notes,:flag_for_admin,:orig_volunteer]
    # if marking isn't enabled it creates errors on delete :(
    conf.actions.add :mark
  end

  # Permissions

  # Only admins can change things in the schedule table
  def create_authorized?
    current_volunteer.super_admin? or current_volunteer.region_admin?
  end

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
  def being_covered
    index("\"when\" >= current_date AND orig_volunteer_id IS NOT NULL AND orig_volunteer_id != volunteer_id","Shifts Being Covered")
  end
  def tardy
    index("\"when\" < current_date AND weight IS NULL and num_reminders >= 3","Missing Data (>= 3 Reminders)")
  end

  def index(filter=nil,header="Entire Log")
    filter = filter.nil? ? "" : " AND #{filter}"
    @shifts = Log.where("region_id IN (#{current_volunteer.region_ids.join(",")})#{filter}")
    @header = header
    render :index
  end

  def new_absence
    respond_to do |format|
      format.html # new_absence.html.erb
    end
  end
 
  def create_absence
    from = Date.new(params[:start_date][:year].to_i,params[:start_date][:month].to_i,params[:start_date][:day].to_i)
    to = Date.new(params[:stop_date][:year].to_i,params[:stop_date][:month].to_i,params[:stop_date][:day].to_i)
    volunteer = Volunteer.find(params[:volunteer_id].to_i)
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
      from += 1
    end
    flash[:notice] = "Scheduled #{n} absences"
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
    unless current_volunteer.super_admin? or current_volunteer.region_admin?(@loc.region)  
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

  def admin_only
    redirect_to(root_path) unless current_volunteer.super_admin? or current_volunteer.region_admin?
  end

end
