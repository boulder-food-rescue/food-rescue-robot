require 'rails_helper'

RSpec.describe Volunteer do
  let(:volunteer) { create(:volunteer) }

  describe '#unassigned?' do
    subject { volunteer }

    it 'returns true if the volunteer has no assignments' do
      subject.assignments.destroy_all
      expect(subject.unassigned?).to eq(true)
    end

    it 'returns false if the volunteer has any assignments' do
      create(:assignment, volunteer: subject)
      expect(subject.unassigned?).to eq(false)
    end
  end

  describe '#needs_training?' do
    subject { volunteer }

    context 'when the volunteer has no completed logs' do
      let(:log_volunteer) { create(:log_volunteer, volunteer: subject) }

      before do
        log_volunteer.log.complete = false
        log_volunteer.log.save!
      end

      it 'returns true' do
        expect(subject.needs_training?).to eq(true)
      end
    end

    context 'when the volunteer has a completed log' do
      let(:log_volunteer) { create(:log_volunteer, volunteer: subject) }

      before do
        log_volunteer.log.complete = true
        log_volunteer.log.hours_spent = 1
        log_volunteer.log.why_zero = Log::WhyZero.invert["No Food"]
        log_volunteer.log.save!
      end

      it 'returns false' do
        expect(subject.needs_training?).to eq(false)
      end
    end
  end
end
