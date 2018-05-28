# frozen_string_literal: true

class CreateScheduleChain
  include Interactor

  delegate :schedule_chain,
           :fail!,
           to: :context

  def call
    fail! unless schedule_chain.save

    # These are normally created as part of a daily task, but often that task runs too late
    # for one-time schedules on the same day.
    generate_log if schedule_chain.one_time? && schedule_chain.detailed_date.today?
  end

  private

  def generate_log
    FoodRobot::LogGenerator::ScheduleChainDecorator.new(schedule_chain).donors.each do |donor|
      FoodRobot::LogGenerator::LogBuilder.new(Date.today, donor, nil).log.save
    end
  end
end
