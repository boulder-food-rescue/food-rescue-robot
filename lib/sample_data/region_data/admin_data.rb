class SampleData
  class RegionData
    class AdminData
      def initialize(region, number)
        @region = region
        @number = number
      end

      def create!
        admins.each(&:save!)
        assignments.each(&:save!)
      end

      private

      attr_reader :region,
                  :number

      def admins
        @admins ||= number.times.map do |i|
          Volunteer.new(
            email: "admin-#{region.name.parameterize}#{i + 1 > 1 ? "-#{i + 1}" : ''}@example.com",
            name: Faker::Name.name,
            phone: Faker::PhoneNumber.phone_number,
            password: 'password',
            assigned: true
          )
        end
      end

      def assignments
        @assignments ||= admins.map do |admin|
          Assignment.new(admin: true) do |assignment|
            assignment.volunteer = admin
            assignment.region = region
          end
        end
      end
    end
  end
end
