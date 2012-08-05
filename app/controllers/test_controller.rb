class TestController < ApplicationController
  def schedule
    @volunteer_schedules = Schedule.where("region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")})")
  end
  def cover
    @open_shifts = Log.where("volunteer_id IS NULL AND recipient_id IS NOT NULL").where("region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")})")
  end
  
  def past_shifts
    @past_shifts = Log.where(:volunteer_id => current_volunteer.id)
  end
  
  #Sepcial setting for admins only
  def admin
  end
  
  #swtich to a particular user
  def switch_user
    if current_volunteer.admin
      sign_out(current_volunteer)
      sign_in(Volunteer.find(params[:volunteer_id].to_i))
    end
    if not current_volunteer.admin
      redirect_to "/"
    else
      render :admin
    end
  end
  
end
