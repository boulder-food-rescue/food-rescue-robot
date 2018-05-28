# frozen_string_literal: true

FactoryGirl.define do
  factory :food_type do
    name 'Some food!'
    region { (Region.all.count >= 5 ? Region.all.sample : create(:region)) }
  end
end
