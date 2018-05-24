# frozen_string_literal: true

FactoryGirl.define do
  factory :log_volunteer do
    association :volunteer
    association :log
    active true
    covering false
  end
end
