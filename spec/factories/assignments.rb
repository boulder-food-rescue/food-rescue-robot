FactoryGirl.define do
  factory :assignment do
    volunteer { (Volunteer.all.count >= 5 ? Volunteer.all.sort_by{ rand }.first : create(:volunteer)) }
    region { (Region.all.count >= 3 ? Region.all.sort_by{ rand }.first : create(:region)) }

    trait :admin do
      admin true
    end
    
    factory :admin_volunteer, traits: [:admin]
  end
end
