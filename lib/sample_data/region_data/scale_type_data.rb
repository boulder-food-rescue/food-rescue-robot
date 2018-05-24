# frozen_string_literal: true

class SampleData
  class RegionData
    class ScaleTypeData
      def initialize(region)
        @region = region
      end

      def create!
        scale_types.each(&:save!)
      end

      private

      attr_reader :region

      def scale_types
        @scale_types ||= [
          { name: 'Bathroom Scale', weight_unit: 'lb' },
          { name: 'Floor Scale', weight_unit: 'lb' },
          { name: 'Guesstimate', weight_unit: 'lb' }
        ].map do |attrs|
          ScaleType.new(attrs) do |scale_type|
            scale_type.region = region
          end
        end
      end
    end
  end
end
