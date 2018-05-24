# frozen_string_literal: true

class SampleData
  class RegionData
    class VolunteerData
      def initialize(region, number)
        @region = region
        @number = number
      end

      def create!
        volunteers.each(&:save!)
        assignments.each(&:save!)
      end

      private

      attr_reader :region,
                  :number

      def volunteers
        @volunteers ||= Array.new(number) do
          name = "#{Faker::Name.first_name} #{Faker::Name.last_name}"

          Volunteer.new(
            email: Faker::Internet.email(name),
            name: name,
            phone: Faker::PhoneNumber.phone_number,
            password: 'password',
            assigned: true
          )
        end
      end

      def assignments
        @assignments ||= volunteers.map do |volunteer|
          Assignment.new(admin: false) do |assignment|
            assignment.volunteer = volunteer
            assignment.region = region
          end
        end
      end
    end
  end
end
