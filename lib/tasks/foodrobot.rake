require 'food_robot'

namespace :foodrobot do

  task(:generate_logs => :environment) do
    Rails.logger = Logger.new(STDOUT)
    # Generate entries for the next 8 days (these shouldn't duplicate)
    9.times { |index| FoodRobot::generate_log_entries(Date.today+index) }
  end

  task(:send_reminders => :environment) do
    Rails.logger = Logger.new(STDOUT)
    FoodRobot::send_reminder_emails(1) # email day-after-pickup
  end

  task(:send_weekly_summary => :environment) do
    if Date.today.sunday?
      Rails.logger = Logger.new(STDOUT)
      FoodRobot::send_weekly_pickup_summary # email pickup summary on sunday
    end
  end

end
