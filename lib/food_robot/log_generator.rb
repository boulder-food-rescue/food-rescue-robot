require 'food_robot/log_generator/existing_logs'
require 'food_robot/log_generator/log_builder'
require 'food_robot/log_generator/schedule_chain_decorator'

module FoodRobot
  class LogGenerator
    attr_reader :number_logs_touched,
                :number_logs_skipped

    def initialize(date, absence)
      @date = date
      @absence = absence

      @number_logs_touched = 0
      @number_logs_skipped = 0
    end

    def generate_logs!
      decorated_schedule_chains.each do |chain|
        puts "Schedule Chain: #{chain.summary}"

        chain.donors.each do |donor|
          existing_log = existing_logs.log_for_donor(donor)

          if existing_log.nil?
            create_log(donor)
            @number_logs_touched += 1
          elsif absence.present?
            mark_absent(existing_log)
            @number_logs_touched += 1
          else
            @number_logs_skipped += 1
          end
        end
      end
    end

    private

    attr_reader :date,
                :absence

    def decorated_schedule_chains
      chains = if absence.present?
                 absence.volunteer.schedule_chains
               else
                 ScheduleChain.where(irregular: false)
               end

      chains.
        includes(schedules: :location).
        select(&:functional?).
        reject { |sc| sc.one_time? && sc.detailed_date != date }.
        reject { |sc| sc.weekly? && sc.day_of_week != date.wday }.
        map { |sc| ScheduleChainDecorator.new(sc) }
    end

    def existing_logs
      @existing_logs ||= ExistingLogs.new(date)
    end

    def create_log(donor)
      LogBuilder.new(date, donor, absence).log.save
    end

    def mark_absent(existing_log)
      existing_log.volunteers -= [absence.volunteer]
      existing_log.absences << absence
      existing_log.save
    end
  end
end
