class SchedulesController < ApplicationController
  before_filter :authenticate_volunteer!

  active_scaffold :schedule do |conf|
    conf.list.sorting = {:day_of_week => 'ASC'}
    conf.list.per_page = 500
    conf.columns = [:region,:day_of_week,:donor,:recipient,:volunteer,:time_start,:time_stop,
                    :irregular,:backup,:transport_type,:food_types,:needs_training,:public_notes,
                    :prior_volunteer,:admin_notes]
    conf.columns[:day_of_week].form_ui = :select
    conf.columns[:day_of_week].options = {:options => [["Unknown/varies",nil],["Sunday",0],
                                                       ["Monday",1],["Tuesday",2],["Wednesday",3],
                                                       ["Thursday",4],["Friday",5],["Saturday",6]]}
    conf.columns[:time_start].description = "e.g., 1400"
    conf.columns[:time_stop].description = "e.g., 1600"
    conf.columns[:donor].form_ui = :select
    conf.columns[:volunteer].form_ui = :select
    conf.columns[:volunteer].clear_link
    conf.columns[:recipient].form_ui = :select
    conf.columns[:food_types].form_ui = :select
    conf.columns[:transport_type].form_ui = :select
    conf.columns[:prior_volunteer].form_ui = :select
    conf.columns[:prior_volunteer].clear_link
    conf.columns[:region].form_ui = :select
    conf.columns[:irregular].label = "Irregular"
    conf.columns[:backup].label = "Backup Pickup"
  end

  # Only admins can change things in the schedule table
  def create_authorized?
    current_volunteer.super_admin? or current_volunteer.region_admin?
  end
#  def update_authorized?(record=nil)
#    current_volunteer.super_admin? or current_volunteer.region_admin?(record.region)
#  end
#  def delete_authorized?(record=nil)
#    current_volunteer.super_admin? or current_volunteer.region_admin?(record.region)
#  end

  # Custom views of the index table
  def open
    if current_volunteer.assignments.length == 0
      @conditions = "1 = 0"
    else
      @conditions = "volunteer_id is NULL"
    end
    index
  end
  def mine
    @conditions = "volunteer_id = '#{current_volunteer.id}'"
    index
  end

  def conditions_for_collection
    unless current_volunteer.assignments.length == 0
      @base_conditions = "region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")})"
    else
      @base_conditions = "region_id IS NULL"
    end
    @conditions.nil? ? @base_conditions : @base_conditions + " AND " + @conditions
  end

  def take
    l = Schedule.find(params[:id])
    l.volunteer = current_volunteer
    l.save
    index
  end

end 
