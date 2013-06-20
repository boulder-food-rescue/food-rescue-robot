module SchedulesHelper

  def readable_start_time schedule
    str = "unknown"
    if use_detailed_hours?
      str = schedule.detailed_start_time.to_s(:clean_time) unless schedule.detailed_start_time.nil?
    else
      str = schedule.time_start unless schedule.time_start.nil?
    end
    str
  end

  def readable_stop_time schedule
   str = "unknown"
   if use_detailed_hours?
      str = schedule.detailed_stop_time.to_s(:clean_time) unless schedule.detailed_stop_time.nil?
    else
      str = schedule.time_stop unless schedule.time_stop.nil?
    end
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
