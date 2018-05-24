# frozen_string_literal: true

module RegionAdmin
  class CreateFoodType
    include Interactor

    def call
      context.food_type = food_type

      context.fail! unless region_present?
      context.fail! unless volunteer_authorized?
      context.fail! unless food_type.save
    end

    private

    def food_type
      @food_type ||= FoodType.new(
        region_id: region_id,
        name:      params[:name]
      )
    end

    def region_present?
      # Region is not validated on the model. Assert that a
      # Food Type has a valid Region here. RF 1-17-17
      region.present?
    end

    def volunteer_authorized?
      volunteer.admin? ||
        adminable_regions.include?(region)
    end

    def adminable_regions
      volunteer.regions.where(assignments: { admin: true })
    end

    def region_id
      region.try(:id)
    end

    def region
      @region ||= Region.find_by_id(params[:region_id])
    end

    def params
      context.params
    end

    def volunteer
      context.volunteer
    end
  end
end
