require 'rails_helper'

RSpec.describe RegionAdmin::UpdateFoodType do

  describe ".call" do
    let(:boulder) { create(:region, name: 'Boulder') }

    let(:food_type) do
      create(
        :food_type,
        region: boulder,
        name:   'Produce'
      )
    end

    context "on success" do
      let(:volunteer) { create(:volunteer, active: true) }

      subject do
        described_class.call(
          volunteer:    volunteer,
          food_type_id: food_type.id,
          params: {
            name: 'Canned'
          }
        )
      end

      context "as a region admin" do
        before do
          create(
            :assignment,
            :admin,
            region:    boulder,
            volunteer: volunteer
          )
        end

        it "returns success" do
          expect(subject.success?).to eq(true)
        end
        
        it "updates the food type" do
          expect{
            subject
          }.to change{
            food_type.reload.name
          }.from('Produce')
          .to('Canned')
        end
      end

      context "as a super admin" do
        before do
          volunteer.admin = true
          volunteer.save
        end

        it "returns success" do
          expect(subject.success?).to eq(true)
        end
        
        it "updates the food type" do
          expect{
            subject
          }.to change{
            food_type.reload.name
          }.from('Produce')
          .to('Canned')
        end
      end
    end

    context "on failure" do
      context "with invalid authorization" do
        let(:volunteer) { create(:volunteer, active: true) }

        subject do
          described_class.call(
            volunteer:    volunteer,
            food_type_id: food_type.id,
            params: {
              name: 'Canned'
            }
          )
        end

        it "returns failure" do
          expect(subject.failure?).to eq(true)
        end
      end
    end
  end
end
