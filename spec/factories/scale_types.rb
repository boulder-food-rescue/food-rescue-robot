# frozen_string_literal: true

FactoryBot.define do
  factory :scale_type do
    name { 'Some scale' }
    weight_unit { 'lb' }
    region { (Region.all.count >= 5 ? Region.all.sample : create(:region)) }
  end
end
