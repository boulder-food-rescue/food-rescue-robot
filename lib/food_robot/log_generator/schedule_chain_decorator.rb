# frozen_string_literal: true

module FoodRobot
  class LogGenerator
    class ScheduleChainDecorator
      def initialize(schedule_chain)
        @schedule_chain = schedule_chain
      end

      def donors
        @donors ||= begin
          donors = schedules.where('location_id IS NOT NULL')
                            .includes(:location)
                            .select(&:pickup_stop?)

          donors.pop if donors.last.location.hub?

          donors
        end
      end

      def summary
        @summary ||= schedules.includes(:location)
                              .select { |s| s.location.present? }
                              .map { |s| "#{s.pickup_stop? ? 'D' : 'R'}#{s.location_id}" }
                              .compact
                              .join(' -> ')
      end

      private

      attr_reader :schedule_chain

      def schedules
        schedule_chain.schedules
      end
    end
  end
end
