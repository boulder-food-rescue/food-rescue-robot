class LogsController < ApplicationController
  before_filter :authenticate_volunteer!

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
#  def update_authorized?(record=nil)
#    current_volunteer == record.volunteer or current_volunteer.super_admin? or current_volunteer.region_admin?(record.region)
#  end
#  def delete_authorized?(record=nil)
#    current_volunteer.super_admin? or current_volunteer.region_admin?(record.region)
#  end

  # Custom views of the index table
  def mine
    @conditions = "volunteer_id = '#{current_volunteer.id}'"
    index
  end
  def mine_upcoming
    @conditions = "volunteer_id = '#{current_volunteer.id}' AND \"when\" >= DATE '#{(Date.today).to_s}'"
    index
  end
  def mine_past
    @conditions = "volunteer_id = '#{current_volunteer.id}' AND \"when\" < DATE '#{(Date.today).to_s}'"
    index
  end
  def open
    @conditions = "volunteer_id is NULL"
    index
  end
  def today
    @conditions = "\"when\" = DATE '#{Date.today.to_s}'"
    index 
  end
  def tomorrow
    @conditions = "\"when\" = DATE '#{(Date.today+1).to_s}'"
    index
  end
  def yesterday
    @conditions = "\"when\" = DATE '#{(Date.today-1).to_s}'"
    index
  end
  def being_covered
    @conditions = "\"when\" >= DATE '#{(Date.today).to_s}' AND volunteer_id IS NOT NULL and volunteer_id != orig_volunteer_id"
    index
  end
  def tardy
    @conditions = "\"when\" < DATE '#{(Date.today).to_s}' AND num_reminders >= 3 AND weight IS NULL"
    index
  end


  def conditions_for_collection
    if current_volunteer.assignments.length == 0
      @base_conditions = "1 = 0"
    else
      @base_conditions = "region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")})"
    end
    @conditions.nil? ? @base_conditions : @base_conditions + " AND " + @conditions
  end

  def new_absence
    respond_to do |format|
      format.html # new_absence.html.erb
    end
  end
 
  def create_absence
    from = Date.new(params[:start_date][:year].to_i,params[:start_date][:month].to_i,params[:start_date][:day].to_i)
    to = Date.new(params[:stop_date][:year].to_i,params[:stop_date][:month].to_i,params[:stop_date][:day].to_i)
    if current_volunteer.admin and !params[:volunteer_id].nil?
      pickups = Schedule.where("volunteer_id = #{params[:volunteer_id].to_i}")
    else
      pickups = Schedule.where("volunteer_id = #{current_volunteer.id}")
    end
    flash[:notice] = pickups.length
    n = 0
    while from <= to
      pickups.each{ |p|
        if from.wday.to_i == p.day_of_week.to_i
          p.food_types.each{ |ft|
            # make sure we don't create more than one for the same absence
            found = Log.where('"when" = ? AND schedule_id = ? AND food_type_id = ?',from,p.id,ft.id)
            flash[:notice] = "#{from} #{p.id} #{ft.id} #{found.to_s.length}"
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
#    flash[:notice] = "Scheduled #{n} absences"
    render :new_absence
  end

  def take
    l = Log.find(params[:id])
    l.volunteer = current_volunteer
    l.save
    mine_upcoming
  end
 
end
