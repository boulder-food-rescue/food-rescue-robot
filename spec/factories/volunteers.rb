# frozen_string_literal: true

FactoryBot.define do
  factory :volunteer do
    sequence(:name) { |n| "John Doe the #{n.ordinalize}" }
    sequence(:email) { |n| "user#{n}@boulderfoodrescue.org" }
    phone { '555-555-5555' }
    password { 'SomePassword' }
    waiver_signed { true }
    waiver_signed_at { Time.zone.now }

    factory :volunteer_with_assignment do
      after(:create) do |v|
        a = create(:assignment, volunteer: v)
        v.assignments << a
        v.assigned = true
        v.save
      end
    end

    trait :not_waived do
      waiver_signed { false }
      waiver_signed_at { nil }
    end
  end
end
