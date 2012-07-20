module LogsHelper

# Set to true to disable emailing and just print the emails to STDOUT
DontDeliverEmails = true

def log_volunteer_column(record)
  if record.volunteer.nil?
    link_to "Take Shift", "/logs/#{record.id}/take"
  else
    record.volunteer.name
  end
end

def log_volunteer_column_attributes(record)
  if record.volunteer.nil?
    {:style => 'background: yellow;'}
  else
    {}
  end
end

# These add "show" links for donor, recipient, and orig_volunteer
def log_donor_column(record)
  if record.donor.nil?
    "-"
  else
    link_to record.donor.name, "/locations/#{record.donor.id}?association=donor&log_id=#{record.id}&parent_scaffold=logs", 
            "class" => "show as_action donor", "data-action" => "show", "data-remote" => "true", "data-position" => "after", 
            "id" => "as_logs-show-donor-#{record.donor.id}-#{record.id}-link"
  end
end

def log_recipient_column(record)
  if record.recipient.nil?
    "-"
  else
    link_to record.recipient.name, "/locations/#{record.recipient.id}?association=recipient&log_id=#{record.id}&parent_scaffold=logs", 
            "class" => "show as_action recipient", "data-action" => "show", "data-remote" => "true", "data-position" => "after", 
            "id" => "as_logs-show-recipient-#{record.recipient.id}-#{record.id}-link"
  end
end

def log_orig_volunteer_column(record)
  if record.orig_volunteer.nil?
    "-"
  else
    link_to record.orig_volunteer.name, "/volunteers/#{record.orig_volunteer.id}?association=orig_volunteer&log_id=#{record.id}&parent_scaffold=logs",
            "class" => "show as_action orig_volunteer", "data-action" => "show", "data-remote" => "true", "data-position" => "after",
            "id" => "as_logs-show-orig_volunteer-#{record.orig_volunteer.id}-#{record.id}-link"
  end
end

# Given a date, generates the corresponding log entries for that
# date based on the /current/ schedule
def generate_log_entries(d=Date.today)
  n = 0
  Schedule.where("day_of_week = ?",d.wday).each{ |s|
    next if s.recipient.nil? or s.donor.nil? 
    next if s.irregular
    s.food_types.each{ |f|
      # don't insert a duplicate log entry if one already exists
      check = Log.where('"when" = ? AND schedule_id = ? AND food_type_id = ?',d,s.id,f.id)
      next if check.length > 0
      # create each scheduled log entry for the given day
      log = Log.new{ |l|
        l.schedule = s
        l.volunteer = s.volunteer
        l.donor = s.donor
        l.recipient = s.recipient
        l.region = s.region
        l.when = d
        l.food_type = f
      }
      n += 1 if log.save
    }
  }
  return n
end

# Sends an email to any volunteer who has a outstanding log entry
# from n or more days ago. Also sends an email to the admin summarizing
# all logs that have seen at least r reminders.
def send_reminder_emails(n=2,r=3)
  naughty_list = {}
  reminder_list = {}
  short_term_cover_list = {}
  pre_reminder_list = {}
  c = 0
  Log.where(:weight => nil).each{ |l| 

    # FUTURE reminders...
    days_future = (l.when - Date.today).to_i
    if days_future == 1 and !l.volunteer.nil? and l.volunteer.pre_reminders_too
      pre_reminder_list[l.volunteer] = [] if pre_reminder_list[l.volunteer].nil?
      pre_reminder_list[l.volunteer].push(l)
      next
    elsif (days_future == 1 or days_future == 2) and l.volunteer.nil?
      short_term_cover_list[l.region] = [] if short_term_cover_list[l.region].nil?
      short_term_cover_list[l.region].push(l)
    end

    # PAST reminders...
    next if l.volunteer.nil?
    days_past = (Date.today - l.when).to_i
    next unless days_past >= n

    l.num_reminders = 0 if l.num_reminders.nil?
    l.num_reminders += 1
    l.save

    reminder_list[l.volunteer] = [] if reminder_list[l.volunteer].nil?
    reminder_list[l.volunteer].push(l)

    if l.num_reminders >= r
      naughty_list[l.region] = [] if naughty_list[l.region].nil?
      naughty_list[l.region].push(l)
    end
  }
  # Send reminders to enter data for PAST pickups
  reminder_list.each{ |v,logs|
    m = Notifier.volunteer_log_reminder(v,logs)
    if DontDeliverEmails
      puts m
    else
      m.deliver
    end
    c += 1

    if v.sms_too and !v.sms_email.nil?
      m = Notifier.volunteer_log_sms_reminder(v,logs)
      if DontDeliverEmails
        puts m
      else
        m.deliver
      end
    end
  }
  # Send reminders to do FUTURE pickups
  pre_reminder_list.each{ |v,logs|
    m = Notifier.volunteer_log_pre_reminder(v,logs)
    if DontDeliverEmails
      puts m
    else
      m.deliver
    end
    c += 1

    if v.sms_too and !v.sms_email.nil?
      m = Notifier.volunteer_log_sms_pre_reminder(v,logs)
      if DontDeliverEmails
        puts m
      else
        m.deliver
      end
    end
  }
  # Remind the admins to cover things without a volunteer...
  if short_term_cover_list.length > 0
    short_term_cover_list.each{ |region,logs|
      m = Notifier.admin_short_term_cover_summary(region,logs)
      if DontDeliverEmails
        puts m
      else
        m.deliver
      end
    }
  end
  # Let the admin know about tardy data entry
  if naughty_list.length > 0
    naughty_list.each{ |region,logs|
      m = Notifier.admin_reminder_summary(region,logs)
      if DontDeliverEmails
        puts m
      else
        m.deliver
      end
    }
  end
  return c
end

def send_weekly_pickup_summary
  Region.all.each{ |r|
    lbs = 0.0
    flagged_logs = []
    biggest = nil
    num_logs = Log.where('region_id = ? AND "when" > ? AND "when" < ?',r.id,Date.today-7,Date.today).count
    num_entered = 0
    Log.where('region_id = ? AND "when" > ? AND "when" < ? AND weight IS NOT NULL',r.id,Date.today-7,Date.today).each{ |l|
      lbs += l.weight
      flagged_logs << l if l.flag_for_admin
      biggest = l if biggest.nil? or l.weight > biggest.weight
      num_entered += 1
    }
    m = Notifier.admin_weekly_summary(r,lbs,flagged_logs,biggest,num_logs,num_entered)
    if DontDeliverEmails
      puts m
    else
      m.deliver
    end

  }
end

end
