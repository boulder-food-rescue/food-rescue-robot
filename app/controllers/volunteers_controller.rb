class VolunteersController < ApplicationController
  before_filter :authenticate_volunteer!

  def create_authorized?
    current_volunteer.super_admin? or current_volunteer.region_admin?
  end
#  def update_authorized?(record=nil)
#    return true if current_volunteer.super_admin?
#    record.regions.each{ |r|
#      return true if current_volunteer.region_admin?(r)
#    }
#    return false
#  end
#  def delete_authorized?(record=nil)
#    return true if current_volunteer.super_admin?
#    record.regions.each{ |r|
#      return true if current_volunteer.region_admin?(r)
#    }
#    return false
#  end

  active_scaffold :volunteer do |conf|
    conf.list.sorting = {:name => 'ASC'}
    conf.columns = [:name,:email,:phone,:cell_carrier,:sms_too,:preferred_contact,:gone_until,:has_car,:is_disabled, 
                    :admin,:on_email_list,:pickup_prefs,:transport_type,:admin_notes,:regions,:created_at]
    conf.update.columns = [:name,:email,:phone,:cell_carrier,:preferred_contact,:sms_too,:pre_reminders_too,:gone_until,:has_car,:is_disabled,
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
    @conditions = "(SELECT COUNT(*) FROM schedules s WHERE s.volunteer_id=volunteers.id)=0"
    index
  end
  def conditions_for_collection
    @conditions
  end

  # Other views entirely
  def home
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
    respond_to do |format|
      format.html # home.html.erb
    end
  end
end 
