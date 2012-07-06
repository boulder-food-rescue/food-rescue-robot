class LogsController < ApplicationController
  before_filter :authenticate_volunteer!

  active_scaffold :log do |conf|
    conf.columns = [:when,:volunteer,:donor,:recipient,:weight,:weighed_by,
                    :description,:transport,:notes,:flag_for_admin,:num_reminders,:orig_volunteer]
    conf.columns[:transport].form_ui = :select
    conf.columns[:transport].label = "Transportation Used"
    conf.columns[:transport].options = {:options => [["Bike","Bike"],["Car","Car"],["Foot","Foot"]]}
    conf.columns[:weighed_by].form_ui = :select
    conf.columns[:weighed_by].options = {:options => [["Bathroom Scale","Bathroom Scale"],["Floor Scale","Floor Scale"],
                                                      ["Guesstimate","Guesstimate"]]}
    conf.columns[:weight].description = "e.g., '42', in pounds"
    conf.columns[:num_reminders].form_ui = :select
    conf.columns[:num_reminders].label = "Reminders Sent"
    conf.columns[:num_reminders].options = {:options => [[0,0],[1,1],[2,2],[3,3],[4,4]]}
    conf.columns[:schedule].form_ui = :select
    conf.columns[:volunteer].form_ui = :select
    conf.columns[:volunteer].clear_link
    conf.columns[:orig_volunteer].form_ui = :select
    conf.columns[:orig_volunteer].label = "Original Volunteer"
    conf.columns[:orig_volunteer].description = "If the shift was covered by someone else, put the original volunteer here"
    conf.columns[:orig_volunteer].clear_link
    conf.columns[:donor].form_ui = :select
    conf.columns[:recipient].form_ui = :select
    conf.update.columns = [:when,:volunteer,:donor,:recipient,:weight,:weighed_by,:description,:transport,:notes,:flag_for_admin]
  end

  # Permissions
  def create_authorized?
    current_volunteer.admin
  end
  #def update_authorized?(record=nil)
  #  return true if current_volunteer.admin
  #  unless params[:id].nil?
  #    return Log.find(params[:id]).volunteer == current_volunteer
  #  else
  #    return false
  #  end
  #end
  def delete_authorized?(record=nil)
    current_volunteer.admin
  end

  # Custom views of the index table
  def mine
    @conditions = "volunteer_id = '#{current_volunteer.id}'"
    index
  end
  def open
    @conditions = "volunteer_id is NULL"
    index
  end
  def conditions_for_collection
    @conditions
  end

  def new_absence
    respond_to do |format|
      format.html # new_absence.html.erb
    end
  end
 
  def create_absence
    from = Date.new(params[:start_date][:year].to_i,params[:start_date][:month].to_i,params[:start_date][:day].to_i)
    to = Date.new(params[:stop_date][:year].to_i,params[:stop_date][:month].to_i,params[:stop_date][:day].to_i)
    pickups = Schedule.where("volunteer_id = #{current_volunteer.id}")
    n = 0
    while from <= to
      pickups.each{ |p|
        if from.wday.to_i == p.day_of_week.to_i
          # make sure we don't create more than one for the same absence
          found = Log.where('"when" = ? AND schedule_id = ?',from,p.id)
          next if found.length > 0

          # create the null record
          lo = Log.new
          lo.orig_volunteer = current_volunteer
          lo.volunteer = nil
          lo.schedule = p
          lo.donor = p.donor
          lo.recipient = p.recipient
          lo.when = from
          lo.save
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
    l.volunteer = current_volunteer
    l.save
    index
  end
 
end
