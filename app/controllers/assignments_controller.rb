class AssignmentsController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only

  def new
    if current_volunteer.super_admin?
      @my_admin_regions = Region.all
      @my_admin_volunteers = Volunteer.all
    else
      @my_admin_regions = current_volunteer.assignments.collect do |assignment|
         assignment.admin ? assignment.region : nil
      end.compact

      admin_region_ids = @my_admin_regions.collect { |my_admin_region| my_admin_region.id }

      @my_admin_volunteers = Volunteer.all.collect do |volunteer|
        ((volunteer.regions.length == 0) ||
        (admin_region_ids & volunteer.regions.collect { |region| region.id }).length > 0) ? volunteer : nil
      end.compact
    end
  end

  def knight
    volunteer = Volunteer.find(params[:volunteer_id])
    region = Region.find(params[:region_id])
    unless current_volunteer.any_admin?(region)
      flash[:notice] = 'Not permitted to do knightings in that region...'
      return redirect_to(root_path)
    end
    assignments = Assignment.where('volunteer_id = ? and region_id = ?', volunteer.id, region.id)
    if assignments.length == 0
      new_assignment = Assignment.new
      new_assignment.volunteer = volunteer
      new_assignment.region = region
      new_assignment.admin = true
      new_assignment.save
    else
      assignments.each do |assignment|
        assignment.admin = !assignment.admin
        assignment.save
      end
    end
    flash[:notice] = 'Assignment succeeded.'
    redirect_to :back
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.any_admin?
  end

end
