require 'rails_helper'

RSpec.describe 'Volunteer waivers' do
  let(:region) {create(:region)}
  let(:volunteer) {create(:volunteer, :driver_waiver_not_signed, regions: [region], assigned: true)}

  context 'As a volunteer' do
    feature 'A volunteer without a signed driver waiver' do
      before do
        login volunteer
      end

      it 'can sign the driver waiver' do
        visit '/waiver/driver-new'
        expect(page).to have_content('PERSONAL VEHICLE USE POLICY')

        check 'accept'
        click_on 'Sign'
        expect(page).to have_content('Waiver signed!')
      end
    end

    feature 'A volunteer with a signed driver waiver' do
      before do
        volunteer.driver_waiver_signed = true
        volunteer.driver_waiver_signed_at = Time.zone.now
        volunteer.save

        login volunteer
      end

      it 'can see the driver waiver is signed' do
        visit '/waiver/driver-new'
        expect(page).to have_content(volunteer.name + ' signed the waiver')
      end
    end
  end

  context 'As a region admin' do
    let(:region_admin) {create(:volunteer, regions: [region], assigned: true)}
    let(:volunteer) {create(:volunteer, regions: [region], assigned: true)}

    before do
      create(:assignment, :admin, volunteer: region_admin, region: region)
      create(:assignment, volunteer: volunteer, region: region)
      login region_admin
    end

    feature 'A region admin has driver waivers to sign' do
      it 'A region admin in the home page can see a list of volunteers tha have their driver waiver signed by region admin' do
        visit root_path
        expect(page).to have_content('Driver waivers to be signed')
        page.has_css?('a[href="volunteers/' + volunteer.id.to_s + '"]')
        page.has_css?('a[href="waiver/driver-new/?volunteer_id=' + volunteer.id.to_s + '"]')
      end


      it 'A region admin can sign the driver waiver of a volunteer in their region' do
        visit 'waiver/driver-new/?volunteer_id=' + volunteer.id.to_s
        expect(page).to have_content('PERSONAL VEHICLE USE POLICY')
        expect(page).to have_content(volunteer.name + ' signed the waiver')
        check 'admin_accept'
        click_on 'Sign'
        expect(page).to have_content('Waiver signed!')
      end
    end


    feature 'A region admin has already signed the driver waiver' do
      before do
        volunteer.driver_waiver_signed_by_admin_id = region_admin.id
        volunteer.driver_waiver_signed_by_admin_at = Time.zone.now
        volunteer.save
      end

      it 'A region admin can see that the driver waiver is signed' do
        visit 'waiver/driver-new/?volunteer_id=' + volunteer.id.to_s
        expect(page).to have_content('PERSONAL VEHICLE USE POLICY')
        expect(page).to have_content(volunteer.name + ' signed the waiver')
        expect(page).to have_content(region_admin.name + ' signed the waiver')
      end
    end
  end

end
