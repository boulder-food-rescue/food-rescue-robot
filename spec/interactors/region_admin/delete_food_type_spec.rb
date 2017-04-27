require 'rails_helper'

RSpec.describe RegionAdmin::DeleteFoodType do
  describe '.call' do
    let(:boulder) { create(:region, name: 'Boulder') }

    let(:food_type) do
      create(
        :food_type,
        region: boulder,
        active: true
      )
    end

    context 'on success' do
      let(:volunteer) { create(:volunteer, active: true) }

      subject do
        described_class.call(
          volunteer:    volunteer,
          food_type_id: food_type.id
        )
      end

      context 'as a region admin' do
        before do
          create(
            :assignment,
            :admin,
            region:    boulder,
            volunteer: volunteer
          )
        end

        it 'returns success' do
          expect(subject.success?).to eq(true)
        end

        it 'soft deletes the food type' do
          expect{
            subject
          }.to change {
            food_type.reload.active
          }.from(true).to(false)
        end
      end

      context 'as a super admin' do
        before do
          volunteer.admin = true
          volunteer.save
        end

        it 'returns success' do
          expect(subject.success?).to eq(true)
        end

        it 'soft deletes the food type' do
          expect{
            subject
          }.to change {
            food_type.reload.active
          }.from(true).to(false)
        end
      end
    end

    context 'on failure' do
      context 'with invalid authorization' do
        let(:volunteer) { create(:volunteer, active: true) }

        subject do
          described_class.call(
            volunteer:    volunteer,
            food_type_id: food_type.id
          )
        end

        it 'returns failure' do
          expect(subject.failure?).to eq(true)
        end
      end
    end
  end
end
