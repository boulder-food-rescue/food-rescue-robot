# frozen_string_literal: true

require 'sample_data/region_data'

class SampleData
  class ExistingDataError < StandardError; end
  class NotDevModeError < StandardError; end

  def self.create_region
    raise NotDevModeError unless Rails.env.development?

    city = Faker::Address.city

    ActiveRecord::Base.transaction do
      region = Region.create!(name: city, title: "#{city} Food Rescue")
      RegionData.new(region).create!
      region
    end
  end
end
