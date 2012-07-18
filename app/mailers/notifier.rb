class Notifier < ActionMailer::Base
  default :from => "robot@boulderfoodrescue.org"
  

  def volunteer_log_reminder(volunteer,logs)
    @logs = logs
    @volunteer = volunteer
    mail(:to => volunteer.email, :subject => "BFR Data Entry Reminder"){ |format| format.text }
  end

  def admin_reminder_summary(region,logs)
    @logs = logs
    to = Assignment.where("region_id = ? AND admin = ?",region.id,true).collect{ |a| a.volunteer.email }.join(",")
    mail(:to => to, :subject => "BFR Data Entry Reminder Summary"){ |format| format.text }
  end
end
