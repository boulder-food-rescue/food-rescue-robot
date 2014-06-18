module ApplicationHelper

  def all_admin_region_volunteer_tuples(whom)
    admin_rids = whom.assignments.collect{ |a| a.admin ? a.region.id : nil }.compact
    Volunteer.all.collect{ |v|
      v_rids = v.regions.collect{ |r| r.id }
      (admin_rids & v_rids).length > 0 ? [v.name+" ["+v.regions.collect{ |r| r.name }.join(",")+"]",v.id] : nil
    }.compact
  end

  def readable_time_until shift
    ret = shift.when.strftime("%b %e") + " ("
    if shift.when == Time.zone.today
      ret += "today"
    elsif shift.when < Time.zone.today
      ret += (Time.zone.today - shift.when).to_i.to_s + " days ago"
    elsif shift.when > Time.zone.today
      ret += (shift.when - Time.zone.today).to_i.to_s + " days from now"
    end
    ret += ")"
    unless shift.schedule.nil?
      ret += " <br>between #{readable_start_time(shift.schedule)} and #{readable_stop_time(shift.schedule)}"
    end
    ret.html_safe
  end

  def readable_start_time schedule
    if schedule.is_a? ScheduleChain
      schedule = schedule.schedules.first
    end
    str = 'unknown'
    str = schedule.schedule_chain.detailed_start_time.to_s(:clean_time) unless schedule.schedule_chain.detailed_start_time.nil?
    str
  end

  def readable_stop_time schedule
    if schedule.is_a? ScheduleChain
      schedule = schedule.schedules.first
    end
    str = "unknown"
    str = schedule.schedule_chain.detailed_stop_time.to_s(:clean_time) unless schedule.schedule_chain.detailed_stop_time.nil?
    str
  end

  def readable_pickup_timespan schedule
    if schedule.is_a? ScheduleChain
      schedule = schedule.schedules.first
    end
    str = "Pickup "
    str+= "irregularly " if schedule.schedule_chain.irregular
    str+= "every "+Date::DAYNAMES[schedule.schedule_chain.day_of_week]+" " if schedule.schedule_chain.weekly? and !schedule.schedule_chain.day_of_week.nil?
    str+= "on "+schedule.schedule_chain.detailed_date.to_s(:long_ordinal)+" " if schedule.schedule_chain.one_time?
    str+= "between "
    str+= readable_start_time schedule
    str+= " and "
    str+= readable_stop_time schedule
    str
  end

end
