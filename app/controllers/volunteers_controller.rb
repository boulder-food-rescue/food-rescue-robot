class VolunteersController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only, :only => [:knight,:unassigned,:shiftless,:shiftless_old,:admin,:switch_user]

  def unassigned
    @filter = "(not assigned or (SELECT COUNT(*) FROM assignments a WHERE a.volunteer_id=volunteers.id)=0) AND ((requested_region_id IS NULL) OR (requested_region_id in (#{current_volunteer.admin_region_ids.join(",")})))"
    @volunteers = Volunteer.where(@filter)
    @header = "Unassigned"
  end

  def assign
    v = Volunteer.find(params[:volunteer_id])
    r = Region.find(params[:region_id])
    a = Assignment.where("volunteer_id = ? and region_id = ?",v.id,r.id)
    if params[:unassign]
      a.each{ |e| e.destroy }
      if v.assignments.length == 0
        v.assigned = false
        v.save
      end
    else
      if a.length == 0
        a = Assignment.new
        a.volunteer = v
        a.region = r
        a.save
      end
      v.assigned = true
      v.save
      unless params[:send_welcome_email].nil? or params[:send_welcome_email].to_i != 1
        m = Notifier.region_welcome_email(r,v)
        m.deliver unless m.nil?
      end
    end
    redirect_to :action => "unassigned", :alert => "Assignment worked"
  end

  def shiftless
    index(Volunteer.where(:is_disabled=>false).where("(SELECT COUNT(*) FROM schedules s WHERE s.volunteer_id=volunteers.id)=0 AND 
           (gone_until IS NULL or gone_until < current_date)"),
      "Shiftless") 
  end
  def need_training
    index(Volunteer.where(:is_disabled=>false, :needs_training=>true).where("gone_until IS NULL or gone_until < current_date"),
      "Needs Training")
  end

  def index(base=nil,header="All Volunteers")
    base = Volunteer.all if base.nil?
    @volunteers = base.collect{ |v| (v.regions.collect{ |r| r.id } & current_volunteer.region_ids).length > 0 ? v : nil }.compact
    @header = header
    render :index
  end

  def show
    @v = Volunteer.find(params[:id])
    unless current_volunteer.super_admin? or (current_volunteer.region_ids & @v.region_ids).length > 0
      flash[:notice] = "Can't view volunteer for a region you're not assigned to..."
      redirect_to(root_path)
      return
    end
  end

  def destroy
    @v = Volunteer.find(params[:id])
    return unless check_permissions(@v)
    @v.destroy
    redirect_to(request.referrer)
  end

  def new
    @volunteer = Volunteer.new
    @action = "create"
    @regions = Region.all
    if current_volunteer.super_admin?
      @my_admin_regions = @regions
    else
      @my_admin_regions = current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
    end
    session[:my_return_to] = request.referer
    render :new
  end

  def check_permissions(v)
    unless current_volunteer.super_admin? or (current_volunteer.admin_region_ids & v.region_ids).length > 0 or
           current_volunteer == v
      flash[:notice] = "Not authorized to create/edit volunteers for that region"
      redirect_to(root_path)
      return false
    end
    return true
  end

  def create
    @volunteer = Volunteer.new(params[:volunteer])
    return unless check_permissions(@volunteer)
    # can't set admin bits from CRUD controls
    @volunteer.admin = false
    @volunteer.assignments.each{ |r| r.admin = false }
    if @volunteer.save
      flash[:notice] = "Created successfully."
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:notice] = "Didn't save successfully :("
      render :new
    end
  end

  def edit
    @volunteer = Volunteer.find(params[:id])
    return unless check_permissions(@volunteer)
    @regions = Region.all
    if current_volunteer.super_admin?
      @my_admin_regions = @regions
    else
      @my_admin_regions = current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
    end
    @action = "update"
    session[:my_return_to] = request.referer
    render :edit
  end

  def update
    @volunteer = Volunteer.find(params[:id])
    return unless check_permissions(@volunteer)
    # can't set admin bits from CRUD controls
    params[:volunteer].delete(:admin) 
    params[:volunteer][:assignments].each{ |a| a.delete(:admin) } unless params[:volunteer][:assignments].nil?
    if @volunteer.update_attributes(params[:volunteer])
      flash[:notice] = "Updated Successfully."
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:notice] = "Update failed :("
      render :edit
    end
  end

  # switch to a particular user
  def switch_user
    v = Volunteer.find(params[:volunteer_id].to_i)
    vrids = v.regions.collect{ |r| r.id }
    adminrids = current_volunteer.assignments.collect{ |a| a.admin ? a.region.id : nil }.compact
    unless current_volunteer.super_admin? or (vrids & adminrids).length > 0
      flash[:notice] = "You're not authorized to switch to that user!"
      redirect_to(root_path)
      return
    end
    sign_out(current_volunteer)
    sign_in(v)
    flash[:notice] = "Successfully switched to user #{current_volunteer.name}."
    home
  end

  # special settings/stats page for admins only
  def super_admin
  end

  def region_admin
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
  end

  def region_stats
  end

  def waiver
    render :waiver
  end

  def sign_waiver
    if params[:accept].to_i == 1
      current_volunteer.waiver_signed = true
      current_volunteer.waiver_signed_at = Time.now
      current_volunteer.save
      flash[:notice] = "Waiver signed!"
    end
    home
  end

  def knight
    unless current_volunteer.super_admin?
      flash[:notice] = "You're not permitted to do that!"
      redirect_to(root_path)
      return
    end
    v = Volunteer.find(params[:volunteer_id])
    v.admin = !v.admin
    v.save
    admin
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.any_admin?
  end

  def home
    if !current_volunteer.waiver_signed
      waiver
      return
    end
    today = Date.today
    
    #Upcoming pickup list
    @upcoming_pickups = Log.where(:when => today...(today + 7)).where(:volunteer_id => current_volunteer)
    @sncs_pickups = Log.where(:when => today...(today+7), :complete => false, :volunteer_id => nil).order("\"when\"").collect{ |l| 
      (current_volunteer.region_ids.include? l.region_id) ? l : nil }.compact
    
    #To Do Pickup Reports
    @to_do_reports = Log.where('"logs"."when" <= ?', today).where("NOT complete").where(:volunteer_id => current_volunteer)
    
    #Last 10 pickups
    @last_ten_pickups = Log.where(:volunteer_id => current_volunteer).where("complete").order('"logs"."when" DESC').limit(10)
    
    #Pickup Stats
    @completed_pickup_count = Log.count(:conditions => {:volunteer_id => current_volunteer})
    @total_food_rescued = Log.joins(:log_parts).where(:volunteer_id => current_volunteer).where("complete").sum(:weight)
    @dis_traveled = 0.0
    Log.where(:volunteer_id => current_volunteer).where("complete").each do |pickup|
      if pickup.schedule != nil
        donor = pickup.donor
        recipient = pickup.recipient
        unless donor.nil? or recipient.nil? or donor.lng.nil? or donor.lat.nil? or recipient.lat.nil? or recipient.lng.nil?
          radius = 6371.0
          dLat = (donor.lat - recipient.lat) * Math::PI / 180.0
          dLon = (donor.lng - recipient.lng) * Math::PI / 180.0
          lat1 = recipient.lat * Math::PI / 180.0
          lat2 = donor.lat * Math::PI / 180.0
          
          a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2)
          c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
          @dis_traveled += radius * c
        end
      end
    end

    if current_volunteer.assignments.length == 0
      @unassigned = true
      @base_conditions = nil
    else
      @unassigned = false
      @base_conditions = " AND region_id IN (#{current_volunteer.assignments.collect{ |a| a.region_id }.join(",")})"
    end

    # FIXME: the below is Sean's code. It's quite nonDRY and should be cleaned up substantially
    @pickups = Log.where("volunteer_id = ? AND complete",current_volunteer.id)
    @lbs = 0.0
    @human_pct = 0.0
    @num_pickups = {}
    @num_covered = 0
    @biggest = nil
    @earliest = nil
    @bike = TransportType.where("name = 'Bike'").shift
    @by_month = {}
    @pickups.each{ |l|
      l.transport_type = @bike if l.transport_type.nil?
      @num_pickups[l.transport_type] = 0 if @num_pickups[l.transport_type].nil?
      @num_pickups[l.transport_type] += 1
      @num_covered += 1 if l.orig_volunteer != current_volunteer and !l.orig_volunteer.nil?
      @lbs += l.summed_weight
      @biggest = l if @biggest.nil? or l.summed_weight > @biggest.summed_weight
      @earliest = l if @earliest.nil? or l.when < @earliest.when
      yrmo = l.when.strftime("%Y-%m")
      @by_month[yrmo] = 0.0 if @by_month[yrmo].nil?
      @by_month[yrmo] += l.summed_weight unless l.summed_weight.nil?
    }
    @human_pct = 100.0*@num_pickups.collect{ |t,c| t.name =~ /car/i ? nil : c }.compact.sum/@num_pickups.values.sum  
    @num_shifts = Schedule.where("volunteer_id = ?",current_volunteer.id).count
    @num_to_cover = Log.where("volunteer_id IS NULL#{@base_conditions}").count
    @num_upcoming = Log.where('volunteer_id = ? AND "when" >= ?',current_volunteer.id,Date.today.to_s).count
    @num_unassigned = Schedule.where("volunteer_id IS NULL AND donor_id IS NOT NULL and recipient_id IS NOT NULL#{@base_conditions}").count
    render :home
  end
end
