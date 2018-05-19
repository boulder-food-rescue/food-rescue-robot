# frozen_string_literal: true

# Run manually with:
# schedule_chain = ScheduleChain.find()
# chain = FoodRobot::LogGenerator::ScheduleChainDecorator.new(schedule_chain)
# donor = chain.donors.first
# date = Date.today - <days til schedule / log should be run)
# FoodRobot::LogGenerator::LogBuilder.new(date, donor, absence).log.save
module FoodRobot
  class LogGenerator
    class LogBuilder
      def initialize(date, donor, absence)
        @date = date
        @donor = donor
        @absence = absence
      end

      def log
        Log.new do |log|
          log.when = date

          log.schedule_chain_id = donor.schedule_chain_id
          log.donor_id = donor.location_id

          log.region_id = schedule_chain.region_id
          log.num_volunteers = schedule_chain.num_volunteers

          log.absences << absence if absence.present?

          log.volunteers << volunteers
          log.recipients << recipients
          log.log_parts << log_parts
        end
      end

      private

      attr_reader :date,
                  :donor,
                  :absence

      def schedule_chain
        donor.schedule_chain
      end

      def volunteers
        volunteers = schedule_chain.volunteers

        if absence.present?
          volunteers.where('volunteers.id != ?', absence.volunteer_id)
        else
          volunteers
        end
      end

      def recipients
        schedule_chain.schedules
                      .eager_load(:location)
                      .where('position > ?', donor.position)
                      .select{ |s| s.location.present? }
                      .select(&:drop_stop?)
                      .map(&:location)
      end

      def log_parts
        donor.schedule_parts.map do |sp|
          LogPart.new(
            food_type_id: sp.food_type_id,
            required: sp.required
          )
        end
      end
    end
  end
end
