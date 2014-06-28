FactoryGirl.define do
  factory :schedule_chain do
    transport_type
    backup false
    temporary false
    irregular false
    scale_type
    region
    admin_notes "some notes"
    public_notes "some other notes"
    expected_weight { rand(200) }
    day_of_week { rand(6) }
    frequency "Weekly"
    difficulty_rating { rand(3) }
    hilliness { rand(3) }

    after(:create) do |s|
      d = create(:donation_schedule,schedule_chain:s)
      r = create(:recipient_schedule,schedule_chain:s)
    end
  end
end
