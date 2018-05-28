# frozen_string_literal: true

module FoodRobot
  class LogGenerator
    class ExistingLogs
      def initialize(date)
        @date = date
      end

      def log_for_donor(donor)
        logs["#{donor.schedule_chain_id}:#{donor.location_id}"]
      end

      private

      attr_reader :date

      def logs
        @logs ||= Log
        .where(when: date)
        .map { |l| ["#{l.schedule_chain_id}:#{l.donor_id}", l] }
        .to_h
      end
    end
  end
end
