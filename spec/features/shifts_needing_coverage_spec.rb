require 'rails_helper'

RSpec.describe 'Shifts needing coverage' do
  let!(:region)    { create(:region) }
  let!(:volunteer) { create(:volunteer, :not_waived, regions: [region], assigned: true) }
  let!(:log)       { create(:log, region_id: volunteer.region_ids[0], when: Time.zone.today + 1.day) }

  feature 'When a volunteer visits the homepage' do
    before(:each) do
      login volunteer
      allow_any_instance_of(ApplicationController).to receive(:current_volunteer).and_return(volunteer)
      allow(volunteer).to receive(:waiver_signed?).and_return(true)
    end

    it 'they see the shifts in their region that need covering' do
      visit root_path

      within page.find('h2', text: 'Shifts Needing Covering').find('+ table') do
        expect(page).to have_link(log.donor.name, href: location_path(log.donor))
        expect(page).to have_button('Take')
        log.food_types.each do |type|
          expect(page).to have_content(type.name)
        end
      end
    end

    it 'and they dont see the shifts out of their region that need covering' do
      other_region_log = create(:log, when: Time.zone.today + 2.days)

      visit root_path

      within page.find('h2', text: 'Shifts Needing Covering').find('+ table') do
        expect(page).to_not have_link(other_region_log.donor.name, href: location_path(other_region_log.donor))
      end
    end
  end
end
