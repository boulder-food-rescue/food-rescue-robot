require 'food_robot'

namespace :foodrobot do

  task(:generate_logs => :environment) do
    Rails.logger = Logger.new(STDOUT)
    # Generate entries for the next few days (shouldn't duplicate...)
    FoodRobot::generate_log_entries(Date.today)
    FoodRobot::generate_log_entries(Date.today+1)
    FoodRobot::generate_log_entries(Date.today+2)
    FoodRobot::generate_log_entries(Date.today+3)
    FoodRobot::generate_log_entries(Date.today+4)
    FoodRobot::generate_log_entries(Date.today+5)
  end

  task(:send_reminders => :environment) do
    Rails.logger = Logger.new(STDOUT)
    FoodRobot::send_reminder_emails(1) # email day-after-pickup
  end

  task(:send_weekly_summary => :environment) do
    if Date.today.sunday?
      Rails.logger = Logger.new(STDOUT)
      FoodRobot::send_weekly_pickup_summary # email day-after-pickup
    end
  end

end
