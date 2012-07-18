class AssignmentsController < ApplicationController
  active_scaffold :assignment do |conf|
    conf.columns = [:admin,:region,:volunteer]
    conf.columns[:region].form_ui = :select
    conf.columns[:volunteer].form_ui = :select
    # if marking isn't enabled it creates errors on delete :(
    conf.actions.add :mark
  end

  # Only admins can change things in the schedule table
  def create_authorized?
    current_volunteer.super_admin? or current_volunteer.region_admin?
  end
#  def update_authorized?(record=nil)
#    current_volunteer.admin or current_volunteer.region_admin?(record.region)
#  end
#  def delete_authorized?(record=nil)
#    return true if current_volunteer.admin
#    current_volunteer.assignments.each{ |a|
#      return true if a.admin and (a.region == record.region)
#    }
#  end

end 
