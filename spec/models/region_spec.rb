require 'rails_helper'

RSpec.describe Region do
  describe ".has_any_handbooks?" do
    let(:region) { build(:region) }

    context "for regions with a handbook" do
      before do
        region.handbook_url = "http://host.domain"
      end

      it "returns true" do
        expect(described_class.has_any_handbooks?([region])).to eq(true)
      end
    end

    context "for regions without a handbook" do
      before do
        region.handbook_url = nil
      end

      it "returns false" do
        expect(described_class.has_any_handbooks?([region])).to eq(false)
      end
    end
  end

  describe "#active_volunteer_count" do
    subject { create(:region) }

    let(:volunteer_1) do
      create(:volunteer)
    end

    let(:volunteer_2) do
      create(:volunteer)
    end

    context "with no schedule chains" do
      it "returns 0" do
        expect(subject.active_volunteer_count).to eq(0)
      end
    end

    context "with schedule chains" do
      let!(:schedule_chain_1) do
        create(
          :schedule_chain,
          region: subject,
          volunteers: [volunteer_1]
        )
      end
      
      let!(:schedule_chain_2) do
        create(
          :schedule_chain,
          region: subject,
          volunteers: [volunteer_1, volunteer_2]
        )
      end

      it "returns the total, unique, volunteers" do
        expect(subject.active_volunteer_count).to eq(2)
      end
    end
  end

  describe "#has_sellers?" do
    subject { create(:region) }

    let!(:hub) do
      create(
        :location,
        region:        subject,
        location_type: 2
      )
    end

    let!(:buyer) do
      create(
        :location,
        region:        subject,
        location_type: 4
      )
    end

    context "with sellers" do
      let!(:seller) do
        create(
          :location,
          region:        subject,
          location_type: 3
        )
      end

      it "returns true" do
        expect(subject.has_sellers?).to eq(true)
      end
    end

    context "with no sellers" do
      it "returns false" do
        expect(subject.has_sellers?).to eq(false)
      end
    end
  end

  describe "#has_buyers?" do
    subject { create(:region) }

    let!(:hub) do
      create(
        :location,
        region:        subject,
        location_type: 2
      )
    end
    
    let!(:seller) do
      create(
        :location,
        region:        subject,
        location_type: 3
      )
    end

    context "with buyers" do
      let!(:buyer) do
        create(
          :location,
          region:        subject,
          location_type: 4
        )
      end

      it "returns true" do
        expect(subject.has_buyers?).to eq(true)
      end
    end

    context "with no buyers" do
      it "returns false" do
        expect(subject.has_buyers?).to eq(false)
      end
    end
  end

  describe "#has_hubs?" do
    subject { create(:region) }
    
    let!(:seller) do
      create(
        :location,
        region:        subject,
        location_type: 3
      )
    end
    
    let!(:buyer) do
      create(
        :location,
        region:        subject,
        location_type: 4
      )
    end

    context "with hubs" do
      let!(:hub) do
        create(
          :location,
          region:        subject,
          location_type: 2
        )
      end

      it "returns true" do
        expect(subject.has_hubs?).to eq(true)
      end
    end

    context "with no hubs" do
      it "returns false" do
        expect(subject.has_hubs?).to eq(false)
      end
    end
  end

  describe "#has_handbook?" do
    subject { described_class.new }

    context "with a handbook url" do
      before do
        subject.handbook_url = "http://host.domain"
      end

      it "returns true" do
        expect(subject.has_handbook?).to eq(true)
      end
    end

    context "without a handbook url" do
      before do
        subject.handbook_url = nil
      end

      it "returns false" do
        expect(subject.has_handbook?).to eq(false)
      end
    end
  end
end
