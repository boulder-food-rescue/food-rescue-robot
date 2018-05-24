# frozen_string_literal: true

FactoryGirl.define do
  factory :absence do
    start_date { Time.zone.today + 1.day }
    stop_date { Time.zone.today + 5.days }
    association :volunteer
  end
end
