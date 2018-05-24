# frozen_string_literal: true

FactoryGirl.define do
  factory :schedule_chain do
    transport_type
    backup false
    temporary false
    irregular false
    scale_type
    region
    admin_notes 'some notes'
    public_notes 'some other notes'
    expected_weight { rand(200) }
    day_of_week { rand(6) }
    frequency 'weekly'
    difficulty_rating { rand(3) }
    hilliness { rand(3) }

    trait :one_time do
      frequency 'one-time'
      day_of_week nil
      detailed_date Date.today + 4.days
    end
  end
end
