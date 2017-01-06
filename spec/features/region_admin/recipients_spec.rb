require 'rails_helper'

RSpec.describe "Region Admin Recipients" do
  feature "Viewing the list of recipients" do
    let(:boulder) { create(:region) }
    let(:denver)  { create(:region) }

    let!(:boulder_recipient) { create(:recipient, region: boulder, name: "Boulder recipient site") }
    let!(:denver_recipient)  { create(:recipient, region: denver,  name: "Denver recipient site") }

    context "as a region admin" do
      let(:volunteer) { create(:volunteer, regions: [], assigned: true) }

      before do
        create(:assignment, :admin, volunteer: volunteer, region: boulder)
        create(:assignment,         volunteer: volunteer, region: denver)

        login volunteer
      end

      it "can see the list of recipients in my administrated regions" do
        visit "/region_admin/recipients"

        expect(page).to have_content("Boulder recipient site")
      end

      it "cannot see recipients from unadministered regions" do
        visit "/region_admin/recipients"

        expect(page).to_not have_content("Denver recipient site")
      end
    end

    context "as a super admin" do
      let(:volunteer) { create(:volunteer, regions: [], assigned: true, admin: true) }

      before do
        create(:assignment, volunteer: volunteer, region: boulder)

        login volunteer
      end

      it "can see the list of recipients in all regions" do
        visit "/region_admin/recipients"

        expect(page).to have_content("Boulder recipient site")
        expect(page).to have_content("Denver recipient site")
      end
    end

    context "as a visitor" do
      it "redirects to sign in" do
        visit "/region_admin/recipients"

        expect(page.current_path).to eq("/volunteers/sign_in")
      end
    end

    context "as a volunteer" do
      let(:volunteer) { create(:volunteer, regions: [boulder], assigned: true) }

      before do
        login volunteer
      end

      it "redirects to home" do
        visit "/region_admin/recipients"

        expect(page.current_path).to eq("/")
      end
    end
  end
end
