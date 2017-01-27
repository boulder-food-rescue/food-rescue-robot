require 'rails_helper'

RSpec.describe "Volunteer takes One-Time Shifts" do
  let(:log) { create(:log, when: "Tue, 31 Jan 2017", donor: donor, log_recipients: [LogRecipient.create(name: "Recipient Name")]) }
  let(:donor) { create(:donor, name: "This is a name") }
  let(:volunteer) { create(:volunteer, :not_waived, regions: [log.region], assigned: true) }
  let(:location) { create(:location) }

  # Expect page to show log entry
  feature "An available one-time shift" do
    before do
      login volunteer
      location
      binding.pry
    end

    it "can view an available shift" do
      visit "/logs/open"
      # Log notes
      expect(page).to have_content("testing 123")
      # When
      expect(page).to have_content("Tue Jan 31")
      # Volunteer name
      expect(page).to have_content("John Doe")
      # Region tagline
      expect(page).to have_content("Knowing is Half the Battle")
      # Recipient name
      expect(page).to have_content("Some place")
      # Donor name
      expect(page).to have_content("This is a name")
    end
  end
end

#Expect cover shift link to _____
