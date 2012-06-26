class LogsController < ApplicationController
  before_filter :authenticate_volunteer!

  active_scaffold :log do |conf|
    conf.columns = [:when,:volunteer,:donor,:recipient,:weight,:weighed_by,
                    :description,:transport,:notes,:flag_for_admin,:num_reminders]
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
    conf.columns[:orig_volunteer].form_ui = :select
    conf.columns[:orig_volunteer].label = "Original Volunteer"
    conf.columns[:orig_volunteer].description = "If the shift was covered by someone else, put the original volunteer here"
    conf.columns[:donor].form_ui = :select
    conf.columns[:recipient].form_ui = :select
  end

  # Permissions
  def create_authorized?
    current_volunteer.admin
  end
  def update_authorized?(record=nil)
    current_volunteer.admin or record.volunteer.email == current_volunteer.email
  end
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


end 
