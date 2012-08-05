class TestController < ApplicationController
  def schedule
    @volunteer_schedules = Schedule.where("region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")})")
  end
  
  def past_shifts
    @past_shifts = Log.where(:volunteer_id => current_volunteer.id).where("\"when\" <= '#{(Date.today).to_s}'")
  end
  
  def unassigned
    @open_schedules = Schedule.where("volunteer_id IS NULL AND recipient_id IS NOT NULL")
  end
  
  def take_pickup
    l = Schedule.find(params[:id])
    l.volunteer = current_volunteer
    l.save
    unassigned
    render :unassigned
  end
  
  def upcoming_shifts
    date = Date.today
    @upcoming_shifts = Log.where(:volunteer_id => current_volunteer.id).where(:when => date...(date + 7))
  end
  
  def cover_shifts
    @open_shifts = Log.where("volunteer_id IS NULL AND recipient_id IS NOT NULL").where("region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")})")
  end
  
  def take_shift
    l = Log.find(params[:id])
    l.volunteer = current_volunteer
    l.save
    cover_shifts
    render :cover_shifts
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
