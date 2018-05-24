# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Volunteer takes One-Time Shifts' do
  let(:donor) { create(:donor, name: 'This is a name') }
  let(:volunteer) { create(:volunteer, :not_waived, regions: [log.region], assigned: true) }
  let!(:location) { create(:location) }
  let!(:recipient) { create(:recipient, name: 'Donor Recipient Name')}
  let(:log_date) { 3.days.from_now }
  let(:log) { create(:log, when: log_date, donor: donor, recipients: [recipient]) }

  # Expect page to show log entry
  feature 'An available one-time shift' do
    before do
      login volunteer
    end

    it 'can view an available shift' do
      visit '/logs/open'
      # Log notes
      expect(page).to have_content('Log Notes Testing123')
      # When
      expect(page).to have_content(log_date.strftime('%a %b %e'))
      # Volunteer name
      expect(page).to have_content('John Doe')
      # Region tagline
      expect(page).to have_content('Knowing is Half the Battle')
      # Recipient name
      expect(page).to have_content('Some place')
      # Donor name
      expect(page).to have_content('This is a name')
    end
  end
end
