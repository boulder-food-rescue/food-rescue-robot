class AssignmentsController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only

  def knight
    v = Volunteer.find(params[:volunteer_id])
    r = Region.find(params[:region_id])
    unless current_volunteer.any_admin?(r)
      flash[:notice] = "Not permitted to do knightings in that region..."
      redirect_to(root_path)
      return
    end
    a = Assignment.where("volunteer_id = ? and region_id = ?",v.id,r.id)
    if a.length == 0
      a = Assignment.new
      a.volunteer = v   
      a.region = r
      a.admin = true
      a.save
    else
      a.each{ |a| 
        a.admin = (not a.admin)
        a.save
      }
    end
    flash[:notice] = "Assignment succeeded."
    redirect_to :back
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.any_admin?
  end

end 
