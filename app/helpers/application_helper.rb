module ApplicationHelper

  def all_admin_region_volunteer_tuples(whom)
    admin_rids = whom.assignments.collect{ |a| a.admin ? a.region.id : nil }.compact
    Volunteer.all.collect{ |v|
      v_rids = v.regions.collect{ |r| r.id }
      (admin_rids & v_rids).length > 0 ? [v.name+" ["+v.regions.collect{ |r| r.name }.join(",")+"]",v.id] : nil
    }.compact
  end

  def use_detailed_hours?
    Webapp::Application.config.use_detailed_hours
  end

  def readable_start_time schedule
    str = "unknown"
    str = schedule.detailed_start_time.to_s(:clean_time) unless schedule.detailed_start_time.nil?
    str
  end

  def readable_stop_time schedule
   str = "unknown"
   str = schedule.detailed_stop_time.to_s(:clean_time) unless schedule.detailed_stop_time.nil?
   str
  end

  def readable_pickup_timespan schedule
    str = "Pickup "
    str+= "irregularly " if schedule.irregular
    str+= "every "+Date::DAYNAMES[schedule.day_of_week]+" " if schedule.weekly?
    str+= "on "+schedule.detailed_date.to_s(:long_ordinal)+" " if schedule.one_time?
    str+= "between "
    str+= readable_start_time schedule
    str+= " and "
    str+= readable_stop_time schedule
    str
  end

end
