require 'rails_helper'

RSpec.describe Location do

  describe "is_donor" do
    let(:donor_type) do
      described_class::LocationType.invert['Donor']
    end

    subject do
      build(
        :location,
        location_type: nil
      )
    end

    context "for donor location types" do
      before do
        subject.location_type = donor_type
      end

      it "returns true" do
        expect(subject.is_donor).to eq(true)
      end
    end

    context "for other location types" do
      it "returns false" do
        expect(subject.is_donor).to eq(false)
      end
    end
  end

  describe "is_hub" do
    let(:hub_type) do
      described_class::LocationType.invert['Hub']
    end

    subject do
      build(
        :location,
        location_type: nil
      )
    end

    context "for hub location types" do
      before do
        subject.location_type = hub_type
      end

      it "returns true" do
        expect(subject.is_hub).to eq(true)
      end
    end

    context "for other location types" do
      it "returns false" do
        expect(subject.is_hub).to eq(false)
      end
    end
  end
end
