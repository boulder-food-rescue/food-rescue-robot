# frozen_string_literal: true

class VolunteerStatsPresenter
  class PickupStatsPresenter
    attr_reader :first_pickup_date

    def initialize(first_pickup_date, logs, time)
      @first_pickup_date = first_pickup_date
      @logs = logs
      @time = time
    end

    def num_completed_pickups
      logs.count
    end

    def total_lbs_rescued
      return 0 if logs.empty?
      @total_lbs_rescued ||= logs.sum(&:summed_weight)
    end

    def avg_lbs_per_week
      return nil if logs.empty?
      total_lbs_rescued / weeks_since_first
    end

    def avg_lbs_per_pickup
      return nil if logs.empty?
      total_lbs_rescued / num_completed_pickups.to_f
    end

    def percent_human_powered_pickups
      return nil if logs.empty?
      human_powered_pickups.count / num_completed_pickups.to_f * 100
    end

    private

    attr_reader :logs,
                :time

    def human_powered_pickups
      @human_powered_pickups ||= logs
      .joins('LEFT OUTER JOIN "transport_types" ON "transport_types"."id" = "logs"."transport_type_id"')
      .where("transport_types.name IS NULL OR NOT transport_types.name ILIKE '%car%'")
    end

    def weeks_since_first
      return 0 if first_pickup_date.nil?
      (time.to_date - first_pickup_date) / 7.0
    end
  end
end
