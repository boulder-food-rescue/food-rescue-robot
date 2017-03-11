class SampleData
  class RegionData
    class RecipientData
      def initialize(region, state_abbr, number)
        @region = region
        @state_abbr = state_abbr
        @number = number
      end

      def create!
        recipients.each(&:save!)
      end

      private

      attr_reader :region,
                  :state_abbr,
                  :number

      def recipients
        @recipients ||= number.times.map do
          Location.new(
            region_id: region.id,
            location_type: Location::LOCATION_TYPES.invert["Recipient"],
            name: PlaceNames::FOOD_BANKS.sample,
            address: "#{Faker::Address.unique.street_address}, #{region.name}, #{state_abbr} #{Faker::Address.zip_code}",
            email: Faker::Internet.unique.email,
            admin_notes: 'These are the admin notes',
            public_notes: 'These are the public notes',
            equipment_storage_info: 'This is the equipment storage info',
            food_storage_info: "This is the food storage info",
            entry_info: 'These are the entry instructions',
            exit_info: 'These are the exit instructions',
            onsite_contact_info: 'This is the onsite contact info'
          )
        end
      end
    end
  end
end
