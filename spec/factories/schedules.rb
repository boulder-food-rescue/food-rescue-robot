# frozen_string_literal: true

FactoryBot.define do
  factory :schedule do
    position { 3 }
    location { Location.all.count >= 5 ? Location.all.sample : create(:location) }

    factory :donation_schedule do
      location { Location.donors.count >= 5 ? Location.donors.sample : create(:donor) }
    end

    factory :recipient_schedule do
      location { Location.recipients.count >= 5 ? Location.recipients.sample : create(:recipient) }
    end
  end
end
