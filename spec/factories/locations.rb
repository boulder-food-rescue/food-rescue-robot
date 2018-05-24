# frozen_string_literal: true

FactoryGirl.define do
  factory :location do
    address { '710 31st St., Boulder, CO, 80303' }
    name 'Some place'
    contact 'Some dude'
    website 'http://foobar.com'
    admin_notes 'Some admin notes'
    public_notes 'Some public notes'
    hours 'Some hours'
    region { (Region.all.count >= 5 ? Region.all.sort_by{ rand }.first : create(:region)) }
    sequence(:email) { |n| "location#{n}@gmail.com" }
    phone '555-555-5555'
    equipment_storage_info 'Or something'
    food_storage_info 'Or something else'
    entry_info 'Yeppers'
    exit_info 'Blah!'
    onsite_contact_info 'Some people'

    factory :recipient do
      location_type Location::LOCATION_TYPES.invert['Recipient']
    end

    factory :donor do
      location_type Location::LOCATION_TYPES.invert['Donor']
    end

    factory :hub do
      location_type Location::LOCATION_TYPES.invert['Hub']
    end
  end
end
