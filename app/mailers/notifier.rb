class Notifier < ActionMailer::Base
  default :from => "robot@boulderfoodrescue.org"

  # Helper method
  def admin_emails_for_region(region)
    Assignment.where("region_id = ? AND admin = ?",region.id,true).collect{ |a| a.volunteer.nil? ? nil : a.volunteer.email }.compact
  end

  def volunteer_log_reminder(volunteer,logs)
    @logs = logs
    @volunteer = volunteer
    mail(:to => volunteer.email, :subject => "Data Entry Reminder"){ |format| format.text }
  end

  def volunteer_log_pre_reminder(volunteer,logs)
    @logs = logs
    @volunteer = volunteer
    mail(:to => volunteer.email, :subject => "Pick-up Reminder"){ |format| format.text }
  end

  def volunteer_log_sms_reminder(volunteer,logs)
    @logs = logs
    @volunteer = volunteer
    return nil if volunteer.nil?
    return nil if volunteer.sms_email.nil?
    mail(:to => volunteer.sms_email, :subject => "Reminder"){ |format| format.text }
  end

  def volunteer_log_sms_pre_reminder(volunteer,logs)
    @logs = logs
    @volunteer = volunteer
    return nil if volunteer.nil?
    return nil if volunteer.sms_email.nil?
    mail(:to => volunteer.sms_email, :subject => "Reminder"){ |format| format.text }
  end

  def admin_reminder_summary(region,logs)
    @logs = logs
    to = admin_emails_for_region(region) 
    mail(:to => to, :subject => "#{region.name} Data Entry Reminder Summary"){ |format| format.text }
  end

  def admin_short_term_cover_summary(region,logs)
    @logs = logs
    to = admin_emails_for_region(region) + Volunteer.where("get_sncs_email").collect{ |v| 
      (v.region_ids.include?(region.id) and !v.gone?) ? v.email : nil 
    }.compact
    mail(:to => to, :subject => "#{region.name} Shifts Needing Coverage Soon (SNCS!)"){ |format| format.text }
  end

  def admin_weekly_summary(region,lbs,flagged_logs,biggest,num_logs,num_entered)
    @region = region
    @lbs = lbs
    @flagged_logs = flagged_logs
    @biggest = biggest
    @num_logs = num_logs
    @num_entered = num_entered
    to = admin_emails_for_region(region) 
    mail(:to => to, :subject => "#{region.name} Weekly Summary"){ |format| format.text }
  end
end
