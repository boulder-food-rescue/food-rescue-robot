require 'rails_helper'

RSpec.describe 'Region Admin Food Types' do
  feature 'Viewing the list of food types' do
    let(:boulder) { create(:region) }
    let(:denver)  { create(:region) }

    let!(:boulder_food_type) do
      create(
        :food_type,
        region: boulder,
        name:   'Boulder food type'
      )
    end

    let!(:denver_food_type) do
      create(
        :food_type,
        region: denver,
        name:   'Denver food type'
      )
    end

    context 'as a region admin' do
      let(:volunteer) { create(:volunteer, regions: [], assigned: true) }

      before do
        create(:assignment, :admin, volunteer: volunteer, region: boulder)
        create(:assignment,         volunteer: volunteer, region: denver)

        login volunteer
      end

      it 'can see the list of food types in administrated regions' do
        visit '/region_admin/food_types'

        expect(page).to have_content('Boulder food type')
      end

      it 'cannot see food types from unadministered regions' do
        visit '/region_admin/food_types'

        expect(page).to_not have_content('Denver food type')
      end
    end

    context 'as a super admin' do
      let(:volunteer) { create(:volunteer, regions: [], assigned: true, admin: true) }

      before do
        create(:assignment, volunteer: volunteer, region: boulder)

        login volunteer
      end

      it 'can see the list of food types in all regions' do
        visit '/region_admin/food_types'

        expect(page).to have_content('Boulder food type')
        expect(page).to have_content('Denver food type')
      end
    end

    context 'as a visitor' do
      it 'redirects to sign in' do
        visit '/region_admin/food_types'

        expect(page.current_path).to eq('/volunteers/sign_in')
      end
    end

    context 'as a volunteer' do
      let(:volunteer) { create(:volunteer, regions: [boulder], assigned: true) }

      before do
        login volunteer
      end

      it 'redirects to home' do
        visit '/region_admin/food_types'

        expect(page.current_path).to eq('/')
      end
    end
  end
end
