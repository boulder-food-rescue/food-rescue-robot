require 'rails_helper'

RSpec.describe "Volunteer waivers" do
  let(:region)    { create(:region) }
  let(:volunteer) { create(:volunteer, :not_waived, regions: [region], assigned: true) }

  feature "A volunteer without a signed waiver" do
    before do
      login volunteer
    end

    it "can sign the waiver" do
      visit "/waiver/new"
      expect(page).to have_content("Volunteer Release and Waiver of Liability")

      check "accept"
      click_on "Sign"
      expect(page).to have_content("Waiver signed!")
    end
  end

  feature "A volunteer with a signed waiver" do
    before do
      volunteer.waiver_signed    = true
      volunteer.waiver_signed_at = Time.zone.now
      volunteer.save

      login volunteer
    end

    it "can see the waiver is signed" do
      visit "/waiver/new"
      expect(page).to have_content("You signed the waiver")
    end
  end
end
