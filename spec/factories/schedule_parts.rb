# frozen_string_literal: true

FactoryBot.define do
  factory :schedule_part do
    association :schedule
    association :food_type
    required false
  end
end
