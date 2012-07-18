class Notifier < ActionMailer::Base
  default :from => "robot@boulderfoodrescue.org"
  

  def volunteer_log_reminder(volunteer,logs)
    @logs = logs
    @volunteer = volunteer
    mail(:to => volunteer.email, :subject => "Data Entry Reminder"){ |format| format.text }
  end

  def admin_reminder_summary(region,logs)
    @logs = logs
    to = Assignment.where("region_id = ? AND admin = ?",region.id,true).collect{ |a| a.volunteer.email }.join(",")
    mail(:to => to, :subject => "#{region.name} Data Entry Reminder Summary"){ |format| format.text }
  end

  def admin_weekly_summary(region,lbs,flagged_logs,biggest,num_logs,num_entered)
    @region = region
    @lbs = lbs
    @flagged_logs = flagged_logs
    @biggest = biggest
    @num_logs = num_logs
    @num_entered = num_entered
    to = Assignment.where("region_id = ? AND admin = ?",region.id,true).collect{ |a| a.volunteer.email }.join(",")
    mail(:to => to, :subject => "#{region.name} Weekly Summary"){ |format| format.text }
  end
end
