FactoryGirl.define do
  factory :log_recipient do
    association :log
    association :recipient
  end
end
