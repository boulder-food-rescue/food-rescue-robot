require 'logger'
require 'csv'

require 'food_robot/log_generator'

module FoodRobot

  # Set to true to disable emailing and just print the emails to STDOUT
  @@DontDeliverEmails = false

  # Given a date, generates the corresponding log entries for that
  # date based on the /current/ schedule
  def self.generate_log_entries(date = Time.zone.today, absence = nil)
    generator = FoodRobot::LogGenerator.new(date, absence)

    generator.generate_logs!

    [
      generator.number_logs_touched,
      generator.number_logs_skipped
    ]
  end

  # Sends an email to any volunteer who has a outstanding log entry
  # from n or more days ago. Also sends an email to the admin summarizing
  # all logs that have seen at least r reminders.
  def self.send_reminder_emails(n=2, r=3)
    naughty_list = {}
    reminder_list = {}
    short_term_cover_list = {}
    pre_reminder_list = {}
    c = 0

    Log.where("NOT complete").each{ |log|
      # FUTURE reminders...
      days_future = (log.when - Time.zone.today).to_i

      if days_future == 1 and !log.volunteers.empty?
        log.volunteers.reject{ |v| not v.pre_reminders_too }.each{ |v|
          pre_reminder_list[v] = [] if pre_reminder_list[v].nil?
          pre_reminder_list[v].push(log)
        }
        next
      elsif (days_future == 1 or days_future == 2) and log.volunteers.empty?
        short_term_cover_list[log.region] = [] if short_term_cover_list[log.region].nil?
        short_term_cover_list[log.region].push(log)
      end

      # PAST reminders...
      next if log.volunteers.empty?
      days_past = (Time.zone.today - log.when).to_i
      next unless days_past >= n

      log.num_reminders = 0 if log.num_reminders.nil?
      log.num_reminders += 1
      log.save

      log.volunteers.each{ |v|
        reminder_list[v] = [] if reminder_list[v].nil?
        reminder_list[v].push(log)

        if log.num_reminders >= r
          naughty_list[log.region] = [] if naughty_list[log.region].nil?
          naughty_list[log.region].push(log)
        end
      }
    }

    # Send reminders to enter data for PAST pickups
    reminder_list.each{ |v, logs|
      m = Notifier.volunteer_log_reminder(v, logs)
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
      short_term_cover_list.each{ |region, logs|
        m = Notifier.admin_short_term_cover_summary(region, logs)
        if @@DontDeliverEmails
          puts m
        else
          m.deliver
        end
      }
    end

    # Let the admin know about tardy data entry
    if naughty_list.length > 0
      naughty_list.each{ |region, logs|
        m = Notifier.admin_reminder_summary(region, logs)
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
      puts num_logs
      zero_logs = []

      logs = Log.joins(:log_parts).select("sum(weight) as weight_sum, sum(count) as count_sum, logs.id, flag_for_admin").where('region_id = ? AND "when" > ? AND "when" < ? AND complete',r.id,Time.zone.today-7,Time.zone.today).group("logs.id, flag_for_admin")

      logs.each{ |log|
        lbs += log.weight_sum.to_f
        zero_logs.push(Log.find(log.id)) if log.weight_sum.to_f == 0.0 and log.count_sum.to_f == 0.0
        flagged_logs << Log.find(log.id) if log.flag_for_admin
        biggest = log if biggest.nil? or log.weight_sum.to_f > biggest.weight_sum.to_f
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
