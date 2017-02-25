FactoryGirl.define do
  factory :log_part do
    required false
    food_type { (FoodType.all.count >= 5 ? FoodType.all.sort_by{ rand }.first : create(:food_type)) }

    factory :complete_log_part do
      weight 42.0
      description 'Or something'
      self.count 5
    end

    factory :required_log_part do
      required true
    end

  end
end
