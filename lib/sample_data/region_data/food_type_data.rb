# frozen_string_literal: true

class SampleData
  class RegionData
    class FoodTypeData
      def initialize(region)
        @region = region
      end

      def create!
        food_types.each(&:save!)
      end

      private

      attr_reader :region

      def food_types
        @food_types ||= [
          { name: 'Produce' },
          { name: 'Baked Goods' },
          { name: 'Frozen Prepared Food' },
          { name: 'Fresh Prepared Food' },
          { name: 'Dairy' }
        ].map do |attrs|
          FoodType.new(attrs) do |food_type|
            food_type.region = region
          end
        end
      end
    end
  end
end
