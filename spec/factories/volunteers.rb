FactoryGirl.define do
  factory :volunteer do
    sequence(:name) { |n| "John Doe the #{n.ordinalize}" }
    sequence(:email) { |n| "user#{n}@boulderfoodrescue.org" }
    phone "555-555-5555"
    password "SomePassword"

    factory :volunteer_with_assignment do
      after(:create) do |v|
        a = create(:assignment,volunteer:v)
        v.assignments << a
        v.assigned = true
        v.save
      end
    end

  end
end
