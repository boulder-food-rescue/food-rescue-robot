FactoryGirl.define do
  factory :volunteer do
    sequence(:name) { |n| "John Doe the #{n.ordinalize}" }
    sequence(:email) { |n| "user#{n}@tcfoodjustice.org" }
    phone '555-555-5555'
    password 'SomePassword'
    waiver_signed true
    waiver_signed_at Time.zone.now
    driver_waiver_signed true
    driver_waiver_signed_at Time.zone.now

    factory :volunteer_with_assignment do
      after(:create) do |v|
        a = create(:assignment, volunteer: v)
        v.assignments << a
        v.assigned = true
        v.save
      end
    end

    trait :not_waived do
      waiver_signed false
      waiver_signed_at nil
    end

    trait :driver_waiver_not_signed do
      driver_waiver_signed false
      driver_waiver_signed_at nil
    end
  end
end
