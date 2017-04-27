require 'rails_helper'

RSpec.describe 'Region Admin Food Types' do
  feature 'Updating an existing food type' do
    let(:boulder) { create(:region) }
    let(:denver)  { create(:region) }

    let(:food_type) do
      create(
        :food_type,
        region: boulder,
        name:   'Canned'
      )
    end

    context 'as a region admin' do
      let(:volunteer) { create(:volunteer, regions: [], assigned: true) }

      before do
        create(:assignment, :admin, volunteer: volunteer, region: boulder)
        create(:assignment,         volunteer: volunteer, region: denver)

        login volunteer
      end

      context 'on success' do
        it 'updates the food type' do
          visit '/region_admin/food_types/#{food_type.id}/edit'

          fill_in :food_type_name, with: 'Frozen'
          click_on 'Update Food type'

          expect(page).to have_content('Updated successfully.')
        end
      end

      context 'on failure' do
        # Can't fail thru the UI. RF 1-18-17
      end
    end

    context 'as a super admin' do
      let(:volunteer) { create(:volunteer, regions: [], assigned: true, admin: true) }

      before do
        create(:assignment, volunteer: volunteer, region: boulder)

        login volunteer
      end

      it 'updates the food type' do
        visit '/region_admin/food_types/#{food_type.id}/edit'

        fill_in :food_type_name, with: 'Frozen'
        click_on 'Update Food type'

        expect(page).to have_content('Updated successfully.')
      end
    end

    context 'as a visitor' do
      it 'redirects to sign in' do
        visit '/region_admin/food_types/#{food_type.id}/edit'

        expect(page.current_path).to eq('/volunteers/sign_in')
      end
    end

    context 'as a volunteer' do
      let(:volunteer) { create(:volunteer, regions: [boulder], assigned: true) }

      before do
        login volunteer
      end

      it 'redirects to home' do
        visit '/region_admin/food_types/#{food_type.id}/edit'

        expect(page.current_path).to eq('/')
      end
    end
  end
end
