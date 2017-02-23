class AssignmentsController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only

  def knight
    volunteer = Volunteer.find(params[:volunteer_id])
    region = Region.find(params[:region_id])
    unless current_volunteer.any_admin?(region)
      flash[:notice] = "Not permitted to do knightings in that region..."
      redirect_to(root_path)
      return
    end
    assignment = Assignment.where("volunteer_id = ? and region_id = ?",volunteer.id,region.id)
    if assignment.length == 0
      assignment = Assignment.new
      assignment.volunteer = volunteer
      assignment.region = region
      assignment.admin = true
      assignment.save
    else
      assignment.each{ |a|
        assignment.admin = (not assignment.admin)
        assignment.save
      }
    end
    flash[:notice] = "Assignment succeeded."
    redirect_to :back
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.any_admin?
  end

end
