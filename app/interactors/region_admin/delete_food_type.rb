module RegionAdmin
  class DeleteFoodType
    include Interactor

    def call
      context.food_type = food_type

      context.fail! unless volunteer_authorized?

      food_type.active = false
      food_type.save
    end

    private

    def food_type
      @food_type ||= FoodType.find(food_type_id)
    end

    def food_type_id
      context.food_type_id
    end

    def volunteer_authorized?
      volunteer.admin? ||
        adminable_regions.include?(food_type_region)
    end

    def adminable_regions
      volunteer.regions.where(assignments: { admin: true })
    end

    def food_type_region
      food_type.region
    end

    def volunteer
      context.volunteer
    end
  end
end
