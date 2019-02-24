# frozen_string_literal: true

FactoryBot.define do
  factory :assignment do
    volunteer { (Volunteer.all.count >= 5 ? Volunteer.all.sample : create(:volunteer)) }
    region { (Region.all.count >= 3 ? Region.all.sample : create(:region)) }

    trait :admin do
      admin true
    end

    factory :admin_volunteer, traits: [:admin]
  end
end
