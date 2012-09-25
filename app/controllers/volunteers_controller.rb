class VolunteersController < ApplicationController
  before_filter :authenticate_volunteer!
  before_filter :admin_only, :only => [:unassigned,:shiftless,:shiftless_old,:admin,:switch_user]

  def create_authorized?
    current_volunteer.super_admin? or current_volunteer.region_admin?
  end

  active_scaffold :volunteer do |conf|
    conf.list.sorting = {:name => 'ASC'}
    conf.columns = [:name,:photo,:email,:phone,:cell_carrier,:sms_too,:preferred_contact,:gone_until,:has_car,:is_disabled, 
                    :admin,:on_email_list,:pickup_prefs,:transport_type,:admin_notes,:regions,:created_at]
    conf.update.columns = [:name,:photo,:email,:phone,:cell_carrier,:preferred_contact,:sms_too,:pre_reminders_too,:gone_until,:has_car,:is_disabled,
                    :admin,:on_email_list,:pickup_prefs,:transport_type,:admin_notes,:regions]
    conf.columns[:is_disabled].label = "Account Deactivated"
    conf.columns[:sms_too].label = "Recieve Texts"
    conf.columns[:sms_too].description = "In addition to emails..."
    conf.columns[:pre_reminders_too].label = "Receive Pre-Reminders"
    conf.columns[:pre_reminders_too].description = "Remind about upcoming pickups"
    conf.columns[:preferred_contact].form_ui = :select
    conf.columns[:regions].form_ui = :select
    conf.columns[:cell_carrier].form_ui = :select
    conf.columns[:cell_carrier].clear_link
    conf.columns[:transport_type].form_ui = :select
    conf.columns[:preferred_contact].options = {:options => [["Email","Email"],["Phone","Phone"],["Text","Text"]]}
    conf.actions.exclude :create
    # if marking isn't enabled it creates errors on delete :(
    conf.actions.add :mark
  end

  def nested?
    return false
  end

  # Custom views of the index table
  def unassigned
    @conditions = "(SELECT COUNT(*) FROM assignments a WHERE a.volunteer_id=volunteers.id)=0"
    index
  end
  def shiftless
    my_rids = current_volunteer.regions.collect{ |r| r.id }
    @volunteers = Volunteer.where("NOT is_disabled AND (SELECT COUNT(*) FROM schedules s WHERE s.volunteer_id=volunteers.id)=0 AND 
                                   (gone_until IS NULL or gone_until < current_date)").collect{ |v| 
      (v.regions.collect{ |r| r.id } & my_rids).length > 0 ? v : nil }.compact
  end
  def shiftless_old
    @conditions = "(SELECT COUNT(*) FROM schedules s WHERE s.volunteer_id=volunteers.id)=0"
    index
  end
  def conditions_for_collection
    @conditions
  end

  # switch to a particular user
  def switch_user
    v = Volunteer.find(params[:volunteer_id].to_i)
    vrids = v.regions.collect{ |r| r.id }
    adminrids = current_volunteer.assignments.collect{ |a| a.admin ? a.region.id : nil }.compact
    unless current_volunteer.super_admin? or (vrids & adminrids).length > 0
      flash[:notice] = "You're not authorized to switch to that user!"
      redirect_to(root_path)
    end
    sign_out(current_volunteer)
    sign_in(v)
    flash[:notice] = "Successfully switched to user #{current_volunteer.name}."
    home
  end

  # special settings/stats page for admins only
  def admin
    render :admin
  end

  def admin_only
    redirect_to(root_path) unless current_volunteer.super_admin? or current_volunteer.region_admin?
  end

  def home
    today = Date.today
    
    #Upcoming pickup list
    @upcoming_pickups = Log.where(:when => today...(today + 7)).where(:volunteer_id => current_volunteer)
    
    #To Do Pickup Reports
    @to_do_reports = Log.where('"logs"."when" <= ?', today).where("weight IS NULL").where(:volunteer_id => current_volunteer)
    
    #Last 10 pickups
    @last_ten_pickups = Log.where(:volunteer_id => current_volunteer).where("weight IS NOT NULL").order('"logs"."when" DESC').limit(10)
    
    #Pickup Stats
    @completed_pickup_count = Log.count(:conditions => {:volunteer_id => current_volunteer})
    @total_food_rescued = Log.where(:volunteer_id => current_volunteer).where("weight IS NOT NULL").sum(:weight)
    completed_pickups = Log.where(:volunteer_id => current_volunteer).where("weight IS NOT NULL")
    @dis_traveled = 0.0
    completed_pickups.each do |pickup|
      if pickup.schedule != nil
        donor = Location.find(pickup.schedule.donor_id)
        recipient = Location.find(pickup.schedule.recipient_id)
        if donor.lng != nil && donor.lat != nil && recipient.lng != nil && recipient.lat != nil
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
    @me = current_volunteer
    @pickups = Log.where("volunteer_id = ? AND weight IS NOT NULL",current_volunteer.id)
    @lbs = 0.0
    @human_pct = 0.0
    @num_pickups = {}
    @num_covered = 0
    @biggest = nil
    @earliest = nil
    @bike = TransportType.where("name = 'Bike'").shift
    @pickups.each{ |l|
      l.transport_type = @bike if l.transport_type.nil?
      @num_pickups[l.transport_type] = 0 if @num_pickups[l.transport_type].nil?
      @num_pickups[l.transport_type] += 1
      @num_covered += 1 if l.orig_volunteer != @me and !l.orig_volunteer.nil?
      @lbs += l.weight
      @biggest = l if @biggest.nil? or l.weight > @biggest.weight
      @earliest = l if @earliest.nil? or l.when < @earliest.when
    }
    @human_pct = 100.0*@num_pickups.collect{ |t,c| t.name =~ /car/i ? nil : c }.compact.sum/@num_pickups.values.sum  
    @num_shifts = Schedule.where("volunteer_id = ?",current_volunteer.id).count
    @num_to_cover = Log.where("volunteer_id IS NULL#{@base_conditions}").count
    @num_upcoming = Log.where('volunteer_id = ? AND "when" >= ?',current_volunteer.id,Date.today.to_s).count
    @num_unassigned = Schedule.where("volunteer_id IS NULL AND donor_id IS NOT NULL and recipient_id IS NOT NULL#{@base_conditions}").count
    
    
    #Food Collected Graphs
    running_total = 0.0
    v_running_total = 0.0
    time = Time.now
    current_month = time.month
    current_year = time.year
    current_day = time.day
    food_per_day = []
    v_food_per_day = []
    food_per_month = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
    v_food_per_month = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
    start_date = Date.new(2012, 6, 26)
    range = Date.today - start_date
    for i in 0..range
      start_date += 1
      total = Log.where(:when => start_date).where("weight IS NOT NULL").where(:region_id => current_volunteer.main_region).sum(:weight)
      v_total = Log.where(:when => start_date).where("weight IS NOT NULL").where(:volunteer_id => current_volunteer).sum(:weight)
      if total != nil
        running_total += total
        food_per_month[start_date.month - 1] += total
      end
      if v_total != nil
        v_running_total += v_total
        v_food_per_month[start_date.month - 1] += v_total
      end
      food_per_day << running_total
      v_food_per_day << v_running_total
    end
    
    @food_chart_day = LazyHighCharts::HighChart.new('area') do |f|
      f.options[:chart][:defaultSeriesType] = "area"
      f.options[:chart][:plotBackgroundColor] = nil
      f.options[:title][:text] = "Food Rescued Since June 26, 2012"
      f.options[:xAxis][:title] = {:enabled => true, :text => "Days Since 06/26/2012"}
      f.options[:yAxis][:title][:text] = "lbs of food"
      f.plot_options(:area => {
        :pointStart => 0,
        :marker => {
          :enabled => false,
          :symbol => 'circle',
          :radius => 2,
          :states => {
            :hover => {
              :enabled => true
            }
          }
        }
      })
      f.series(:name=>'Pounds of Food Rescued in Your Main Region', :data=> food_per_day)
      f.series(:name=>'Pounds of Food Rescued by You', :data=> v_food_per_day)
    end
    
    month_labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    for i in 1..current_month
      month_labels = month_labels.push(month_labels.shift)
      food_per_month = food_per_month.push(food_per_month.shift)
      v_food_per_month = v_food_per_month.push(v_food_per_month.shift)
    end
    
    @food_chart_month = LazyHighCharts::HighChart.new('column') do |f|
      f.options[:chart][:defaultSeriesType] = "column"
      f.options[:chart][:plotBackgroundColor] = nil
      f.options[:title][:text] = "Food Rescued By Month"
        f.options[:xAxis] = {
        :plot_bands => "none",
        :title=>{:text=>"Month"},
        :categories => month_labels}
      f.options[:yAxis][:title][:text] = "lbs of food"
      f.series(:name=>'Pounds of Food Rescued in Your Main Region', :data=> food_per_month)
      f.series(:name=>'Pounds of Food Rescued by You', :data=> v_food_per_month)
    end
    render :home
  end
end
