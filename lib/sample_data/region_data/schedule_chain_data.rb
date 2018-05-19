# frozen_string_literal: true

class SampleData
  class RegionData
    class ScheduleChainData
      def initialize(region, number)
        @region = region
        @number = number
      end

      def create!
        schedule_chains.each(&:save!)
      end

      private

      attr_reader :region,
                  :number

      def schedule_chains
        @schedule_chains ||= Array.new(number) do
          times = random_start_stop_times
          frequency = %w(weekly one-time).sample

          ScheduleChain.new(
            schedules: random_chain_schedules,
            detailed_start_time: times[:start],
            detailed_stop_time: times[:stop],
            detailed_date: 100.days.from_now - rand(600).days,
            difficulty_rating: [true, false].sample ? rand(1..3) : nil,
            hilliness: [true, false].sample ? rand(5) : nil,
            frequency: frequency,
            day_of_week: frequency == 'weekly' ? rand(7) : nil,
            expected_weight: [true, false].sample ? 20 * rand(5) : nil,
            num_volunteers: rand(4),
            backup: false,
            temporary: false,
            irregular: false
          ) do |schedule_chain|
            schedule_chain.transport_type = active_record_random_from(TransportType)
            schedule_chain.region = region
            schedule_chain.volunteers = random_volunteers
          end
        end
      end

      def random_start_stop_times
        start = rand(9...20)

        {
          start: "#{start}:00:00",
          stop: "#{start + rand(1...4)}:00:00"
        }
      end

      def random_chain_schedules
        sched_locations = []

        # Schedule chains have to start with a donor
        sched_locations << active_record_random_from(region.locations.donors)

        # Select some random locations (donors or recipients)
        Array.new(rand(4)) do
          sched_locations << active_record_random_from(region.locations.where('locations.id NOT IN (?)', sched_locations))
        end

        # Schedule chains have to end with a recipient
        sched_locations << active_record_random_from(region.locations.recipients.where('locations.id NOT IN (?)', sched_locations))

        # Build schedules from the selected locations
        sched_locations.map.with_index do |location, i|
          Schedule.new(position: i + 1) do |schedule|
            schedule.location = location
          end
        end
      end

      def random_volunteers
        volunteers = []

        Array.new(rand(3)) do
          volunteers << active_record_random_from(
            volunteers.empty? ?
              region.volunteers :
              region.volunteers.where('volunteers.id NOT IN (?)', volunteers)
          )
        end

        volunteers
      end

      def active_record_random_from(relation)
        relation.first(offset: rand(relation.count))
      end
    end
  end
end
