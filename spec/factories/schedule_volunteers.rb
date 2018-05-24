# frozen_string_literal: true

FactoryGirl.define do
  factory :schedule_volunteer do
    association :volunteer
    association :schedule_chain
    active true
  end
end
