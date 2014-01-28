class VolunteersController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only, :only => [:knight,:unassigned,:shiftless,:shiftless_old,:admin,:switch_user]

  def unassigned
    unassigned = Volunteer.where(:assigned=>false)
    no_assingments = Volunteer.where("((SELECT COUNT(*) FROM assignments a WHERE a.volunteer_id=volunteers.id)=0)")
    unrequested = Volunteer.where(:requested_region_id=>nil)
    requested_my_region = Volunteer.where(:requested_region_id=>current_volunteer.admin_region_ids)
    @volunteers = unassigned | (no_assingments & (unrequested | requested_my_region))
    @header = "Unassigned Volunteers"
  end

  def assign
    v = Volunteer.find(params[:volunteer_id])
    r = Region.find(params[:region_id])
    if params[:unassign]
      Assignment.where(:volunteer_id=>v.id, :region_id=>r.id).each{ |e| e.destroy }
      if v.assignments.length == 0
        v.assigned = false
        v.save
      end
    else
      Assignment.add_volunteer_to_region v, r
      unless params[:send_welcome_email].nil? or params[:send_welcome_email].to_i != 1
        m = Notifier.region_welcome_email(r,v)
        m.deliver unless m.nil?
      end
      v.needs_training = true
      v.save
    end
    redirect_to :action => "unassigned", :alert => "Assignment worked"
  end

  def shiftless
    # TODO: make this more efficient
    @volunteers = Volunteer.all.keep_if do |volunteer|
      volunteer.schedules.length ==0 && (volunteer.gone_until.nil? || volunteer.gone_until < Date.today)
    end
    @header = "Shiftless Volunteers"
    render :index
  end

  def need_training
    @volunteers = Volunteer.where(:is_disabled=>false, :needs_training=>true).keep_if do |volunteer|
      (volunteer.gone_until.nil? || volunteer.gone_until < Date.today)
    end
    @header = "Volunteers Needing Training"
    render :index
  end

  def index
    @volunteers = Volunteer.all.collect{ |v| (v.regions.collect{ |r| r.id } & current_volunteer.region_ids).length > 0 ? v : nil }.compact
    @header = "All Volunteers"
    render :index
  end

  def show
    @v = Volunteer.find(params[:id])
    unless current_volunteer.super_admin? or (current_volunteer.region_ids & @v.region_ids).length > 0
      flash[:error] = "Can't view volunteer for a region you're not assigned to..."
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
      flash[:error] = "Not authorized to create/edit volunteers for that region"
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
      flash[:error] = "Didn't save successfully :("
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
      flash[:error] = "Update failed :("
      render :edit
    end
  end

  # switch to a particular user
  def switch_user
    v = Volunteer.find(params[:volunteer_id].to_i)
    vrids = v.regions.collect{ |r| r.id }
    adminrids = current_volunteer.assignments.collect{ |a| a.admin ? a.region.id : nil }.compact
    unless current_volunteer.super_admin? or (vrids & adminrids).length > 0
      flash[:error] = "You're not authorized to switch to that user!"
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
    @pounds_per_year = {}
    @pounds_per_month = {}
    @first_recorded_pickup = nil
    @per_volunteer = {}
    @per_volunteer2 = {}
      
    Log.select("sum(weight) as weight_sum, `logs`.`id`, `logs`.`when`, logs.transport_type_id, logs.orig_volunteer_id, logs.volunteer_id").
        joins(:log_parts).where("complete and region_id IN (#{current_volunteer.admin_region_ids.join(",")})").
        group("`logs`.`id`, `logs`.`when`, logs.transport_type_id, logs.orig_volunteer_id, logs.volunteer_id").
        each{ |l|
      @pounds_per_year[l.when.year] = 0 if @pounds_per_year[l.when.year].nil?
      @pounds_per_year[l.when.year] += l.weight_sum.to_f
      mokey = l.when.strftime("%Y-%m")
      @pounds_per_month[mokey] = 0 if @pounds_per_month[mokey].nil?
      @pounds_per_month[mokey] += l.weight_sum.to_f
      @first_recorded_pickup = l.when if @first_recorded_pickup.nil? or l.when < @first_recorded_pickup
      next if l.volunteer.nil?
      @per_volunteer[l.volunteer.id] = {:weight => 0.0, :count => 0, :bycar => 0, :covered => 0} if @per_volunteer[l.volunteer.id].nil?
      @per_volunteer2[l.volunteer.id] = {:weight => 0.0, :count => 0, :bycar => 0, :covered => 0} if @per_volunteer2[l.volunteer.id].nil?
      if l.when >= (Date.today << 12)
        @per_volunteer[l.volunteer.id][:weight] += l.weight_sum.to_f
        @per_volunteer[l.volunteer.id][:count] += 1
        @per_volunteer[l.volunteer.id][:bycar] += 1 if !l.transport_type.nil? and l.transport_type.name == "Car"
        @per_volunteer[l.volunteer.id][:covered] += 1 if l.orig_volunteer != nil and l.orig_volunteer != l.volunteer
      end
      if l.when >= (Date.today << 1)
        @per_volunteer2[l.volunteer.id][:weight] += l.weight_sum.to_f
        @per_volunteer2[l.volunteer.id][:count] += 1
        @per_volunteer2[l.volunteer.id][:bycar] += 1 if !l.transport_type.nil? and l.transport_type.name == "Car"
        @per_volunteer2[l.volunteer.id][:covered] += 1 if l.orig_volunteer != nil and l.orig_volunteer != l.volunteer
      end
    }

    @pounds_per_month_data = []
    @pounds_per_month_labels = @pounds_per_month.keys.sort
    @pounds_per_month_labels.each{ |i|
      @pounds_per_month_data << @pounds_per_month[i]
    }
    @pounds_per_year_data = []
    @pounds_per_year_labels = @pounds_per_year.keys.sort
    @pounds_per_year_labels.each{ |i|
      @pounds_per_year_data << @pounds_per_year[i]
    }

    @lazy_volunteers = Volunteer.select("volunteers.id, name, email, count(*) as count, max(`logs`.`when`) as last_date").
            joins(', logs').where("volunteers.id=logs.volunteer_id").group("volunteers.id, name, email")

    @region_locations = Location.where(:region_id=>current_volunteer.admin_region_ids)
  end

  def waiver
    render :waiver
  end

  def sign_waiver
    if params[:accept].to_i == 1
      current_volunteer.waiver_signed = true
      current_volunteer.waiver_signed_at = Time.zone.now
      current_volunteer.save
      flash[:notice] = "Waiver signed!"
    end
    home
  end

  def knight
    unless current_volunteer.super_admin?
      flash[:error] = "You're not permitted to do that!"
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
    today = Time.zone.today
    
    @open_shift_count = Schedule.open_in_regions(current_volunteer.region_ids).length

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

    @unassigned = current_volunteer.unassigned?

    # FIXME: the below is Sean's code. It's quite nonDRY and should be cleaned up substantially
    @pickups = Log.picked_up_by current_volunteer.id
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
    @num_shifts = current_volunteer.schedules.count
    @num_to_cover = Log.needing_coverage.count
    @num_upcoming = Log.upcoming_for(current_volunteer.id).count
    @num_unassigned = Schedule.unassigned_in_regions(current_volunteer.assignments).count
    render :home
  end
end
