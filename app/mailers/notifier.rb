class Notifier < ActionMailer::Base
  AdminEmail = "cphillips@smallwhitecube.com"
  default :from => "robot@boulderfoodrescue.org"

  def volunteer_log_reminder(log)
    @log = log
    # commented out for debugging purposes
    #mail(:to => log.volunteer.email){ |format| format.text }
    mail(:to => AdminEmail, :subject => "BFR Data Entry Reminder"){ |format| format.text }
  end

  def admin_reminder_summary(logs)
    @logs = logs
    mail(:to => AdminEmail, :subject => "BFR Data Entry Reminder Summary"){ |format| format.text }
  end
end
