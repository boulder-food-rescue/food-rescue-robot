# frozen_string_literal: true

require 'sample_data/region_data/admin_data'
require 'sample_data/region_data/donor_data'
require 'sample_data/region_data/food_type_data'
require 'sample_data/region_data/place_names'
require 'sample_data/region_data/recipient_data'
require 'sample_data/region_data/scale_type_data'
require 'sample_data/region_data/schedule_chain_data'
require 'sample_data/region_data/volunteer_data'

class SampleData
  class RegionData
    def initialize(region)
      @region = region
    end

    def create!
      food_type_data.create!
      scale_type_data.create!

      admin_data.create!
      volunteer_data.create!
      donor_data.create!
      recipient_data.create!
      schedule_chain_data.create!
    end

    private

    attr_reader :region

    def state_abbr
      @state_abbr ||= Faker::Address.state_abbr
    end

    def food_type_data
      FoodTypeData.new(region)
    end

    def scale_type_data
      ScaleTypeData.new(region)
    end

    def admin_data
      AdminData.new(region, 2)
    end

    def volunteer_data
      VolunteerData.new(region, 60)
    end

    def donor_data
      DonorData.new(region, state_abbr, 60)
    end

    def recipient_data
      RecipientData.new(region, state_abbr, 60)
    end

    def schedule_chain_data
      ScheduleChainData.new(region, 60)
    end
  end
end
