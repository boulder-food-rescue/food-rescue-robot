require 'rails_helper'

RSpec.describe ReactivateVolunteer do
  describe '::call' do
    subject do
      described_class.call(
        volunteer: volunteer
      )
    end

    let(:volunteer) do
      create(:volunteer, active: false)
    end

    it 'activates the volunteer' do
      expect(subject.success?).to eq(true)
      expect(volunteer.reload.active).to eq(true)
    end

    it 'fails if it cannot save the volunteer' do
      expect(volunteer).to receive(:update_attribute).and_return false
      expect(subject.success?).to eq(false)
    end

    context 'volunteer is already active' do
      let(:volunteer) do
        create(:volunteer, active: true)
      end

      it 'leaves volunteer active' do
        expect(subject.success?).to eq(true)
        expect(volunteer.reload.active).to eq(true)
      end
    end
  end
end
