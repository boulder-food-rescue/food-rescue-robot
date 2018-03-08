require 'rails_helper'

RSpec.describe RegionAdmin::CreateFoodType do
  describe '.call' do
    let(:boulder) { create(:region, name: 'Boulder') }

    context 'on success' do
      let(:volunteer) { create(:volunteer, active: true) }

      subject do
        described_class.call(
          volunteer: volunteer,
          params: {
            region_id: boulder.id,
            name:      'Canned'
          }
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

        it 'creates a new food type' do
          expect{
            subject
          }.to change {
            FoodType.count
          }.by(1)
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

        it 'creates a new food type' do
          expect{
            subject
          }.to change {
            FoodType.count
          }.by(1)
        end
      end
    end

    context 'on failure' do
      context 'with invalid authorization' do
        let(:denver) { create(:region, name: 'Denver') }

        let(:volunteer) { create(:volunteer, active: true) }

        subject do
          described_class.call(
            volunteer: volunteer,
            params: {
              region_id: boulder.id,
              name:      'Canned'
            }
          )
        end

        before do
          create(
            :assignment,
            :admin,
            region:    denver,
            volunteer: volunteer
          )
        end

        it 'returns failure' do
          expect(subject.failure?).to eq(true)
        end
      end

      context 'with invalid params' do
        let(:volunteer) { create(:volunteer, active: true) }

        subject do
          described_class.call(
            volunteer: volunteer,
            params: {
              region_id: 'boulder',
              name:      'Canned'
            }
          )
        end

        it 'returns failure' do
          expect(subject.failure?).to eq(true)
        end

        it 'does not create a food type' do
          expect{
            subject
          }.to_not change {
            FoodType.count
          }
        end

        it 'sets the food type' do
          expect(subject.food_type).to_not be_nil
        end
      end
    end
  end
end
