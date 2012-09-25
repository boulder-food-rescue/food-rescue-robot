class AssignmentsController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only

  def index
    @regions = Region.all
    if current_volunteer.super_admin?
      @my_admin_regions = @regions
      @my_admin_volunteers = Volunteer.all
    else
      @my_admin_regions = current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
      adminrids = @my_admin_regions.collect{ |m| m.id }
      @my_admin_volunteers = Volunteer.all.collect{ |v| 
        ((v.regions.length == 0) or (adminrids & v.regions.collect{ |r| r.id }).length > 0) ? v : nil }.compact
    end
    render :index
  end

  def assign
    v = Volunteer.find(params[:volunteer_id])
    r = Region.find(params[:region_id])
    a = Assignment.where("volunteer_id = ? and region_id = ?",v.id,r.id)
    if params[:unassign]
      a.each{ |e| e.destroy }
    else
      if a.length == 0
        a = Assignment.new
        a.volunteer = v
        a.region = r
        a.save
      end
    end
    index
  end

  def knight
    v = Volunteer.find(params[:volunteer_id])
    r = Region.find(params[:region_id])
    unless current_volunteer.super_admin? or current_volunteer.region_admin?(r)
      flash[:notice] = "Not permitted to do knightings in that region..."
      redirect_to(root_path)
    end
    a = Assignment.where("volunteer_id = ? and region_id = ?",v.id,r.id)
    bit = (params[:unassign]) ? false : true
    if a.length == 0
      a = Assignment.new
      a.volunteer = v   
      a.region = r
      a.admin = bit
      a.save
    else
      a.each{ |a| 
        a.admin = bit
        a.save
      }
    end
    flash[:notice] = "Assignment succeeded."
    index
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.super_admin? or current_volunteer.region_admin?
  end

end 
