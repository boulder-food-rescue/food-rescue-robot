# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Location do
  describe 'donor?' do
    let(:donor_type) do
      described_class::LOCATION_TYPES.invert['Donor']
    end

    subject do
      build(
        :location,
        location_type: nil
      )
    end

    context 'for donor location types' do
      before do
        subject.location_type = donor_type
      end

      it 'returns true' do
        expect(subject.donor?).to eq(true)
      end
    end

    context 'for other location types' do
      it 'returns false' do
        expect(subject.donor?).to eq(false)
      end
    end
  end

  describe 'hub?' do
    let(:hub_type) do
      described_class::LOCATION_TYPES.invert['Hub']
    end

    subject do
      build(
        :location,
        location_type: nil
      )
    end

    context 'for hub location types' do
      before do
        subject.location_type = hub_type
      end

      it 'returns true' do
        expect(subject.hub?).to eq(true)
      end
    end

    context 'for other location types' do
      it 'returns false' do
        expect(subject.hub?).to eq(false)
      end
    end
  end
end
