FactoryGirl.define do
  factory :volunteer do
    sequence(:name) { |n| "John Doe the #{n.ordinalize}" }
    sequence(:email) { |n| "user#{n}@boulderfoodrescue.org" }
    phone "555-555-5555"
    password "SomePassword"
    confirmed_at Time.zone.now

    factory :volunteer_with_assignment do
      after(:create) do |v|
        a = create(:assignment,volunteer:v)
        volunteer.assignments << a
        a.assigned = true
      end
    end

  end
end
