# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ToggleSuperAdmin do
  describe '::call' do
    let(:volunteer) do
      create(:volunteer)
    end

    subject do
      described_class.call(
        volunteer: volunteer
      )
    end

    it 'fails if it cannot save the volunteer' do
      expect(volunteer).to receive(:save).and_return false
      expect(subject.success?).to eq(false)
    end

    context 'is admin' do
      let(:volunteer) do
        create(:volunteer, admin: true)
      end

      it 'unsets the admin flag' do
        expect(subject.success?).to eq(true)
        expect(volunteer.reload.admin).to eq(false)
      end
    end

    context 'is not admin' do
      let(:volunteer) do
        create(:volunteer, admin: false)
      end

      it 'sets the admin flag' do
        expect(subject.success?).to eq(true)
        expect(volunteer.reload.admin).to eq(true)
      end
    end
  end
end
