# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CreateScheduleChain do
  describe '::call' do
    subject do
      described_class.call(
        schedule_chain: chain
      )
    end

    let(:chain) do
      build(:schedule_chain, :one_time)
    end

    it 'saves the schedule' do
      expect(subject.success?).to eq(true)
      expect(chain).to be_persisted
    end

    it 'does not create rescue logs' do
      expect {
        subject
      }.to_not(change { Log.count })
    end

    it 'fails if it cannot save the schedule' do
      expect(chain).to receive(:save).and_return false
      expect(subject.success?).to eq(false)
    end

    context 'schedule is one time and same day' do
      let!(:donor) { create(:donation_schedule, schedule_chain: chain, location: create(:hub), position: 1) }
      let!(:recipient) { create(:recipient_schedule, schedule_chain: chain, location: create(:hub), position: 2) }

      let(:chain) do
        create(:schedule_chain, :one_time, detailed_date: Date.today)
      end

      it 'creates rescue logs' do
        expect {
          subject
        }.to change { Log.count }.by(1)
      end
    end
  end
end
