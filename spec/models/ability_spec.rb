require 'rails_helper'

RSpec.describe Ability do
  describe 'super admins' do
    let(:super_admin) { create(:volunteer, admin: true) }

    subject { Ability.new(super_admin) }

    it 'can manage everything' do
      expect(subject.can?(:manage, :all)).to be(true)
    end
  end
end
