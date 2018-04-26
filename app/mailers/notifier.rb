class Notifier < ActionMailer::Base
  add_template_helper(ApplicationHelper)
  default from: 'robot@boulderfoodrescue.org'
  #ForceTo = "cphillips@smallwhitecube.com"
  FORCE_TO = nil

  def admin_emails_for_region(region)
    Assignment.where('region_id = ? AND admin = ?', region.id, true).collect{ |a| a.volunteer.nil? ? nil : a.volunteer.email }.compact
  end

  def schedule_collision_warning(schedule, shifts)
    @schedule = schedule
    @shifts = shifts
    to = admin_emails_for_region(@schedule.region)
    to = FORCE_TO.nil? ? to : FORCE_TO
    mail(to: to, subject: '[FoodRobot] Schedule Collision Warning'){ |format| format.html }
  end

  def region_welcome_email(region, volunteer)
    return nil if region.welcome_email_text.nil? or region.welcome_email_text.strip.empty?
    @welcome_email_text = region.welcome_email_text
    to = FORCE_TO.nil? ? volunteer.email : FORCE_TO
    mail(to: to, subject: '[FoodRobot] Welcome to the Food Rescue Robot!'){ |format| format.html }
  end

  def volunteer_log_reminder(volunteer, logs)
    @logs = logs
    @volunteer = volunteer
    to = FORCE_TO.nil? ? volunteer.email : FORCE_TO
    mail(to: to, subject: '[FoodRobot] Reminder: How much food did you pick up!?'){ |format| format.html }
  end

  def volunteer_log_pre_reminder(volunteer, logs)
    @logs = logs
    @logs = logs
    @volunteer = volunteer
    to = FORCE_TO.nil? ? volunteer.email : FORCE_TO
    mail(to: to, subject: '[FoodRobot] Upcoming Pick-up Reminder'){ |format| format.html }
  end

  def volunteer_log_sms_reminder(volunteer, logs)
    @logs = logs
    @volunteer = volunteer
    return nil if volunteer.nil?
    return nil if volunteer.sms_email.nil?
    to = FORCE_TO.nil? ? volunteer.sms_email : FORCE_TO
    mail(to: to, subject: '[Food Robot]'){ |format| format.text }
  end

  def volunteer_log_sms_pre_reminder(volunteer, logs)
    @logs = logs
    @volunteer = volunteer
    return nil if volunteer.nil?
    return nil if volunteer.sms_email.nil?
    to = FORCE_TO.nil? ? volunteer.sms_email : FORCE_TO
    mail(to: to, subject: '[FoodRobot]'){ |format| format.text }
  end

  def admin_reminder_summary(region, logs)
    @logs = logs
    to = admin_emails_for_region(region)
    to = FORCE_TO.nil? ? to : FORCE_TO
    mail(to: to, subject: "[FoodRobot] #{region.name} Data Entry Reminder Summary"){ |format| format.html }
  end

  def admin_short_term_cover_summary(region, logs)
    @logs = logs
    to = admin_emails_for_region(region) + Volunteer.where('get_sncs_email').collect{ |v|
      (v.region_ids.include?(region.id)) ? v.email : nil
    }.compact
    to = FORCE_TO.nil? ? to : FORCE_TO
    mail(to: to, subject: "[FoodRobot] #{region.name} Shifts Needing Coverage Soon (SNCS!)"){ |format| format.html }
  end

  def admin_weekly_summary(region, lbs, flagged_logs, biggest, num_logs, num_entered, zero_logs)
    @region = region
    @lbs = lbs
    @flagged_logs = flagged_logs
    @biggest = biggest
    @num_logs = num_logs
    @num_entered = num_entered
    @zero_logs = zero_logs
    to = admin_emails_for_region(region)
    to = FORCE_TO.nil? ? to : FORCE_TO
    mail(to: to, subject: "[FoodRobot] #{region.name} Weekly Summary"){ |format| format.html }
  end
end
