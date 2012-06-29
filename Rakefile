#!/usr/bin/env rake
# Add your own tasks in files placed in lib/tasks ending in .rake,
# for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

require File.expand_path('../config/application', __FILE__)

Webapp::Application.load_tasks

task(:generate_logs => :environment) do
  include LogsHelper
  generate_log_entries(Date.today+1)
end

task(:send_reminders => :environment) do
  include LogsHelper
  send_reminder_emails(-1) # email day-before-pickup
#   send_reminder_emails(0) # email day-of-pickup
#  send_reminder_emails(1) # email day-after-pickup
end
