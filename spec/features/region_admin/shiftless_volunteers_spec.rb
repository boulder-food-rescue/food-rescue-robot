require 'rails_helper'

RSpec.describe 'Region Admin Shiftless Volunteers' do
  feature 'Viewing shiftless volunteers' do
    let(:boulder) { create(:region, name: 'Boulder') }
    let(:denver) { create(:region, name: 'Denver') }

    context 'as a region admin' do
      let(:current_volunteer) { create(:volunteer, regions: [], assigned: true) }
      let(:shiftless_volunteer) { create(:volunteer, assigned: true) }
      let(:shiftless_volunteer_denver) { create(:volunteer, regions: [denver], assigned: true) }
      let(:volunteer_with_shifts) { create(:volunteer, assigned: true) }
      let(:schedule_chain) { create(:schedule_chain, region: boulder) }

      before do
        create(:assignment, :admin, volunteer: current_volunteer, region: boulder)
        create(:assignment, volunteer: shiftless_volunteer, region: boulder)
        create(:assignment, volunteer: shiftless_volunteer_denver, region: denver)
        create(:assignment, volunteer: volunteer_with_shifts, region: boulder)
        create(:schedule_volunteer, volunteer: volunteer_with_shifts, schedule_chain: schedule_chain)

        login current_volunteer
      end

      it 'displays volunteers without shifts' do
        visit '/volunteers/shiftless'

        expect(page).to have_content(shiftless_volunteer.name)
        expect(page).to_not have_content(volunteer_with_shifts.name)
        expect(page).to_not have_content(shiftless_volunteer_denver.name)
        expect(page).to have_content('Email List')
      end
    end

    context 'as a volunteer' do
      let(:volunteer) { create(:volunteer, regions: [boulder], assigned: true) }

      before do
        login volunteer
      end

      it 'redirects to home' do
        visit '/volunteers/shiftless'

        expect(page.current_path).to eq('/')
      end
    end
  end
end
