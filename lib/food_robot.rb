# frozen_string_literal: true

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
  def self.send_reminder_emails(max_days_past=2, reminder_level=3)
    naughty_list = {}
    reminder_list = {}
    short_term_cover_list = {}
    pre_reminder_list = {}
    c = 0

    Log.where('NOT complete AND created_at > ?', DateTime.now - 6.months).each do |log|
      # FUTURE reminders...
      days_future = (log.when - Time.zone.today).to_i

      if days_future == 1 and !log.volunteers.empty?
        log.volunteers.reject{ |vol| not vol.pre_reminders_too }.each{ |vol|
          pre_reminder_list[vol] = [] if pre_reminder_list[vol].nil?
          pre_reminder_list[vol].push(log)
        }
        next
      elsif (days_future == 1 or days_future == 2) and log.volunteers.empty?
        short_term_cover_list[log.region] = [] if short_term_cover_list[log.region].nil?
        short_term_cover_list[log.region].push(log)
      end

      # PAST reminders...
      next if log.volunteers.empty?
      days_past = (Time.zone.today - log.when).to_i
      next unless days_past >= max_days_past

      log.num_reminders = 0 if log.num_reminders.nil?
      log.num_reminders += 1
      log.save

      log.volunteers.each do |vol|
        reminder_list[vol] = [] if reminder_list[vol].nil?
        reminder_list[vol].push(log)

        if log.num_reminders >= reminder_level
          naughty_list[log.region] = [] if naughty_list[log.region].nil?
          naughty_list[log.region].push(log)
        end
      end
    end

    # Send reminders to enter data for PAST pickups
    reminder_list.each do |volunteer, logs|
      m = Notifier.volunteer_log_reminder(volunteer, logs)
      if @@DontDeliverEmails
        puts m
      else
        m.deliver
      end
      c += 1

      if volunteer.sms_too and !volunteer.sms_email.nil?
        m = Notifier.volunteer_log_sms_reminder(volunteer, logs)
        if @@DontDeliverEmails
          puts m
        else
          m.deliver
        end
      end
    end

    # Send reminders to do FUTURE pickups
    pre_reminder_list.each do |volunteer, logs|
      m = Notifier.volunteer_log_pre_reminder(volunteer, logs)
      if @@DontDeliverEmails
        puts m
      else
        m.deliver
      end
      c += 1

      if volunteer.sms_too and !volunteer.sms_email.nil?
        m = Notifier.volunteer_log_sms_pre_reminder(volunteer, logs)
        if @@DontDeliverEmails
          puts m
        else
          m.deliver
        end
      end
    end

    # Remind the admins to cover things without a volunteer...
    unless short_term_cover_list.empty?
      short_term_cover_list.each do |region, logs|
        msg = Notifier.admin_short_term_cover_summary(region, logs) if region.present?
        if @@DontDeliverEmails
          puts msg
        else
          msg.deliver
        end
      end
    end

    # Let the admin know about tardy data entry
    unless naughty_list.empty?
      naughty_list.each do |region, logs|
        next unless region.present?

        msg = Notifier.admin_reminder_summary(region, logs)
        if @@DontDeliverEmails
          puts msg
        else
          msg&.deliver
        end
      end
    end
    return c
  end

  def self.send_weekly_pickup_summary
    Region.all.each do |r|
      puts r.name
      lbs = 0.0
      flagged_logs = []
      biggest = nil
      num_logs = Log.where('region_id = ? AND "when" > ? AND "when" < ?', r.id, Time.zone.today-7, Time.zone.today).count
      num_entered = 0
      next unless num_logs.positive?
      puts num_logs
      zero_logs = []

      logs = Log.joins(:log_parts).select('sum(weight) as weight_sum, sum(count) as count_sum, logs.id, flag_for_admin').where('region_id = ? AND "when" > ? AND "when" < ? AND complete', r.id, Time.zone.today-7, Time.zone.today).group('logs.id, flag_for_admin')

      logs.each{ |log|
        lbs += log.weight_sum.to_f
        zero_logs.push(Log.find(log.id)) if log.weight_sum.to_f == 0.0 and log.count_sum.to_f == 0.0
        flagged_logs << Log.find(log.id) if log.flag_for_admin
        biggest = log if biggest.nil? or log.weight_sum.to_f > biggest.weight_sum.to_f
        num_entered += 1
      }
      next if biggest.nil?
      biggest = Log.find(biggest.id)
      m = Notifier.admin_weekly_summary(r, lbs, flagged_logs, biggest, num_logs, num_entered, zero_logs)
      if @@DontDeliverEmails
        puts m
      else
        m.deliver
      end
    end
  end
end
