require 'logger'
require 'csv'

module FoodRobot 
  
  # Set to true to disable emailing and just print the emails to STDOUT
  @@DontDeliverEmails = true

  # Given a date, generates the corresponding log entries for that
  # date based on the /current/ schedule
  def self.generate_log_entries(d=Time.zone.today)
    n = 0
    Schedule.where("day_of_week = ?",d.wday).each{ |s|
      next if s.recipient.nil? or s.donor.nil? 
      next if s.irregular
      # don't insert a duplicate log entry if one already exists
      check = Log.where('"when" = ? AND schedule_id = ?',d,s.id)
      next if check.length > 0
      # create each scheduled log entry for the given day
      log = Log.new{ |l|
        l.schedule = s
        l.volunteer = s.volunteers.first # TODO: verify this assumption makes sense
        l.donor = s.donor
        l.recipient = s.recipient
        l.region = s.region
        l.when = d
        l.food_types = s.food_types
      }
      n += 1 if log.save
    }
    return n
  end

  # Sends an email to any volunteer who has a outstanding log entry
  # from n or more days ago. Also sends an email to the admin summarizing
  # all logs that have seen at least r reminders.
  def self.send_reminder_emails(n=2,r=3)
    naughty_list = {}
    reminder_list = {}
    short_term_cover_list = {}
    pre_reminder_list = {}
    c = 0
    Log.where("NOT complete").each{ |l| 

      # FUTURE reminders...
      days_future = (l.when - Time.zone.today).to_i
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
      days_past = (Time.zone.today - l.when).to_i
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
      if @@DontDeliverEmails
        puts m
      else
        m.deliver
      end
      c += 1

      if v.sms_too and !v.sms_email.nil?
        m = Notifier.volunteer_log_sms_reminder(v,logs)
        if @@DontDeliverEmails
          puts m
        else
          m.deliver
        end
      end
    }
    # Send reminders to do FUTURE pickups
    pre_reminder_list.each{ |v,logs|
      m = Notifier.volunteer_log_pre_reminder(v,logs)
      if @@DontDeliverEmails
        puts m
      else
        m.deliver
      end
      c += 1

      if v.sms_too and !v.sms_email.nil?
        m = Notifier.volunteer_log_sms_pre_reminder(v,logs)
        if @@DontDeliverEmails
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
        if @@DontDeliverEmails
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
        if @@DontDeliverEmails
          puts m
        else
          m.deliver
        end
      }
    end
    return c
  end

  def self.send_weekly_pickup_summary
    Region.all.each{ |r|
      puts r.name
      lbs = 0.0
      flagged_logs = []
      biggest = nil
      num_logs = Log.where('region_id = ? AND "when" > ? AND "when" < ?',r.id,Time.zone.today-7,Time.zone.today).count
      num_entered = 0
      next unless num_logs > 0
      zero_logs = []
      Log.joins(:log_parts).select("sum(weight) as weight_sum, sum(count) as count_sum, logs.id, flag_for_admin").where('region_id = ? AND "when" > ? AND "when" < ? AND complete',r.id,Time.zone.today-7,Time.zone.today).group("logs.id, flag_for_admin").each{ |l|
        lbs += l.weight_sum.to_f
        zero_logs.push(Log.find(l.id)) if l.weight_sum.to_f == 0.0 and l.count_sum.to_f == 0.0
        flagged_logs << Log.find(l.id) if l.flag_for_admin
        biggest = l if biggest.nil? or l.weight_sum.to_f > biggest.weight_sum.to_f
        num_entered += 1
      }
      next if biggest.nil?
      biggest = Log.find(biggest.id)
      m = Notifier.admin_weekly_summary(r,lbs,flagged_logs,biggest,num_logs,num_entered,zero_logs)
      if @@DontDeliverEmails
        puts m
      else
        m.deliver
      end

    }
  end  

end
