module SchedulesHelper

  def readable_start_time schedule
    if use_detailed_hours?
      schedule.detailed_start_time.to_s(:clean_time)
    else
      schedule.time_start
    end
  end

  def readable_stop_time schedule
   if use_detailed_hours?
      schedule.detailed_stop_time.to_s(:clean_time)
    else
      schedule.time_stop
    end    
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
