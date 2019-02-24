# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Schedule do
  describe 'Schedule' do
    let(:super_admin) { create(:volunteer, admin: true) }

    it 'validates super_admin' do
      expect(super_admin).to be_valid
    end
  end
end
