require 'rails_helper'

RSpec.describe Ability do
  describe 'super admins' do
    let(:super_admin) { create(:volunteer, admin: true) }

    subject { Ability.new(super_admin) }

    it 'can manage everything' do
      expect(subject.can?(:manage, :all)).to be(true)
    end
  end

  describe 'region admins' do
    let(:region_admin) { create(:volunteer) }
    let(:region) { create(:region) }

    before do
      create(:assignment, :admin, volunteer: region_admin, region: region)
    end

    subject { Ability.new(region_admin) }

    describe 'regions' do
      it 'can update their admin regions' do
        expect(subject.can?(:update, region)).to eq(true)
      end

      it 'cannot update other regions' do
        other_region = create(:region)
        expect(subject.can?(:update, other_region)).to eq(false)
      end
    end

    describe 'food types' do
      let(:food_type) { create(:food_type, region: region) }

      it 'can manage food types in their admin regions' do
        expect(subject.can?(:manage, food_type)).to eq(true)
      end

      it 'cannot manage other food types' do
        other_food_type = create(:food_type)
        expect(subject.can?(:manage, other_food_type)).to eq(false)
      end
    end

    describe 'locations' do
      let(:location) { create(:location, region: region) }

      it 'can manage locations in their admin regions' do
        expect(subject.can?(:manage, location)).to eq(true)
      end

      it 'cannot manage other locations' do
        other_location = create(:location)
        expect(subject.can?(:manage, other_location)).to eq(false)
      end
    end

    describe 'scale types' do
      let(:scale_type) { create(:scale_type, region: region) }

      it 'can manage scale types in their admin regions' do
        expect(subject.can?(:manage, scale_type)).to eq(true)
      end

      it 'cannot manage other scale types' do
        other_scale_type = create(:scale_type)
        expect(subject.can?(:manage, other_scale_type)).to eq(false)
      end
    end
  end
end
