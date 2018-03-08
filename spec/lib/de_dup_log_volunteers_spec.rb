require 'rails_helper'
require 'de_dup_log_volunteers'

RSpec.describe DeDupLogVolunteers do
  describe '::de_duplicate' do
    subject { described_class.de_duplicate }

    let(:log) { create(:log) }
    let(:volunteer) { create(:volunteer) }

    let!(:log_volunteer_dups) {
      begin
        Array.new(3) do |i|
          create(:log_volunteer, log: log, volunteer: volunteer, created_at: i.days.ago)
        end
      rescue ActiveRecord::RecordInvalid
        skip 'duplicate log_volunteers with active = true are now prevented'
      end
    }

    it 'does not delete any data' do
      expect { subject }.not_to change { LogVolunteer.count }
    end

    it 'finds all active duplicates and sets all but the most recent to inactive' do
      expect(log_volunteer_dups.map(&:active)).to all(eq(true))

      subject

      log_volunteer_dups.each(&:reload)

      expect(log_volunteer_dups.first.active).to eq(true)
      expect(log_volunteer_dups[1..-1].map(&:active)).to all(eq(false))
    end
  end
end
