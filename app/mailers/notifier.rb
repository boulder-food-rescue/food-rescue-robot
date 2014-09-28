class Notifier < ActionMailer::Base
  add_template_helper(ApplicationHelper)
  default :from => "robot@boulderfoodrescue.org"

  def admin_emails_for_region(region)
    Assignment.where("region_id = ? AND admin = ?",region.id,true).collect{ |a| a.volunteer.nil? ? nil : a.volunteer.email }.compact
  end

  def schedule_collision_warning(schedule,shifts)
    @schedule = schedule
    @shifts = shifts
    to = admin_emails_for_region(@schedule.region)
    mail(:to => to, :bcc => "cphillips@smallwhitecube.com", :subject => "[FoodRobot] Schedule Collision Warning"){ |format| format.html }
  end

  def region_welcome_email(region,volunteer)
    return nil if region.welcome_email_text.nil? or region.welcome_email_text.strip.length == 0
    @welcome_email_text = region.welcome_email_text
    mail(:to => volunteer.email, :bcc => "cphillips@smallwhitecube.com", :subject => "[FoodRobot] Welcome to the Food Rescue Robot!"){ |format| format.html }
  end  

  def volunteer_log_reminder(volunteer,logs)
    @logs = logs
    @volunteer = volunteer
    mail(:to => volunteer.email, :bcc => "cphillips@smallwhitecube.com", :subject => "[FoodRobot] Data Entry Reminder"){ |format| format.html }
  end

  def volunteer_log_pre_reminder(volunteer,logs)
    @logs = logs
    @logs = logs
    @volunteer = volunteer
    mail(:to => volunteer.email, :bcc => "cphillips@smallwhitecube.com", :subject => "[FoodRobot] Pick-up Reminder"){ |format| format.html }
  end

  def volunteer_log_sms_reminder(volunteer,logs)
    @logs = logs
    @volunteer = volunteer
    return nil if volunteer.nil?
    return nil if volunteer.sms_email.nil?
    mail(:to => volunteer.sms_email, :bcc => "cphillips@smallwhitecube.com", :subject => "Reminder"){ |format| format.text }
  end

  def volunteer_log_sms_pre_reminder(volunteer,logs)
    @logs = logs
    @volunteer = volunteer
    return nil if volunteer.nil?
    return nil if volunteer.sms_email.nil?
    mail(:to => volunteer.sms_email, :bcc => "cphillips@smallwhitecube.com", :subject => "Reminder"){ |format| format.text }
  end

  def admin_reminder_summary(region,logs)
    @logs = logs
    to = admin_emails_for_region(region) 
    mail(:to => to, :bcc => "cphillips@smallwhitecube.com", :subject => "[FoodRobot] #{region.name} Data Entry Reminder Summary"){ |format| format.html }
  end

  def admin_short_term_cover_summary(region,logs)
    @logs = logs
    to = admin_emails_for_region(region) + Volunteer.where("get_sncs_email").collect{ |v| 
      (v.region_ids.include?(region.id) and !v.gone?) ? v.email : nil 
    }.compact
    mail(:to => to, :bcc => "cphillips@smallwhitecube.com", :subject => "#{region.name} Shifts Needing Coverage Soon (SNCS!)"){ |format| format.html }
  end

  def admin_weekly_summary(region,lbs,flagged_logs,biggest,num_logs,num_entered,zero_logs)
    @region = region
    @lbs = lbs
    @flagged_logs = flagged_logs
    @biggest = biggest
    @num_logs = num_logs
    @num_entered = num_entered
    @zero_logs = zero_logs
    to = admin_emails_for_region(region) 
    mail(:to => to, :bcc => "cphillips@smallwhitecube.com", :subject => "#{region.name} Weekly Summary"){ |format| format.html }
  end
end