# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Region Admin Donors' do

  feature 'Viewing the list of donors' do
    let(:boulder) { create(:region) }
    let(:denver)  { create(:region) }

    let!(:boulder_donor) { create(:donor, region: boulder, name: 'Boulder donor site') }
    let!(:denver_donor)  { create(:donor, region: denver,  name: 'Denver donor site') }

    context 'as a region admin' do
      let(:volunteer) { create(:volunteer, regions: [], assigned: true) }

      before do
        create(:assignment, :admin, volunteer: volunteer, region: boulder)
        create(:assignment,         volunteer: volunteer, region: denver)

        login volunteer
      end

      it 'can see the list of donors in my administrated regions' do
        visit '/region_admin/donors'

        expect(page).to have_content('Boulder donor site')
      end

      it 'cannot see donors from unadministered regions' do
        visit '/region_admin/donors'

        expect(page).to_not have_content('Denver donor site')
      end
    end

    context 'as a super admin' do
      let(:volunteer) { create(:volunteer, regions: [], assigned: true, admin: true) }

      before do
        create(:assignment, volunteer: volunteer, region: boulder)

        login volunteer
      end

      it 'can see the list of donors in all regions' do
        visit '/region_admin/donors'

        expect(page).to have_content('Boulder donor site')
        expect(page).to have_content('Denver donor site')
      end
    end

    context 'as a visitor' do
      it 'redirects to sign in' do
        visit '/region_admin/donors'

        expect(page.current_path).to eq('/volunteers/sign_in')
      end
    end

    context 'as a volunteer' do
      let(:volunteer) { create(:volunteer, regions: [boulder], assigned: true) }

      before do
        login volunteer
      end

      it 'redirects to home' do
        visit '/region_admin/donors'

        expect(page.current_path).to eq('/')
      end
    end
  end
end
