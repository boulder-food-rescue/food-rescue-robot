FactoryGirl.define do
  factory :schedule do
    position 3
    location (Location.all.count >= 5 ? Location.all.sort_by{ rand }.first : create(:location))

    factory :donation_schedule do
      location (Location.donors.count >= 5 ? Location.donors.sort_by{ rand }.first : create(:donor))
    end

    factory :recipient_schedule do
      location (Location.recipients.count >= 5 ? Location.recipients.sort_by{ rand }.first : create(:recipient))
    end
  end
end
