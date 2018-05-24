# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SignWaiver do
  describe '::call' do
    let(:time) { Time.zone.now.change(sec: 0) }

    let(:volunteer) do
      create(
        :volunteer,
        waiver_signed: false,
        waiver_signed_at: nil
      )
    end

    subject do
      described_class.call(
        volunteer: volunteer,
        signed_at: time
      )
    end

    it 'marks the volunteer as having signed the waiver' do
      expect(subject.success?).to eq(true)
      expect(volunteer.reload.waiver_signed).to eq(true)
    end

    it 'saves the time that the volunteer signed the waiver' do
      expect(subject.success?).to eq(true)
      expect(volunteer.reload.waiver_signed_at).to eq(time)
    end

    it 'fails if it cannot save the volunteer' do
      expect(volunteer).to receive(:save).and_return false
      expect(subject.success?).to eq(false)
    end
  end
end
