require 'rails_helper'

RSpec.describe "Volunteer takes One-Time Shifts" do
  let(:log) { create(:log, when: "Tue, 31 Jan 2017") }
  let(:volunteer) { create(:volunteer, :not_waived, regions: [log.region], assigned: true) }
  let(:location) { create(:location) }
  #Not sure how 'Recipient(s)' works, location.log_recipients returns ActiveRecord collection, location.recip_category returns 'nil'. What should the log show for this attribute?

  # Expect page to show log entry
  feature "An available one-time shift" do
    before do
      login volunteer
      location
    end

    it "can view an available shift" do
      visit "/logs/open"
      expect(page).to have_content("testing 123")
      expect(page).to have_content("Tue Jan 31")
      expect(page).to have_content("John Doe")
      expect(page).to have_content("Knowing is Half the Battle")
      #need to check for recipient attribute
    end
  end
end

#Expect cover shift link to _____
