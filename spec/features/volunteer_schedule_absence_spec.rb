require 'rails_helper'

RSpec.describe AbsencesController do
  let(:volunteer_with_assignment) { create :volunteer_with_assignment }
  let(:volunteer_without_assignment) { create :volunteer }
  let(:admin) { create :volunteer_with_assignment, admin: true }

  # it_behaves_like 'an authenticated indexable resource'

  describe 'GET #create' do
    
    context 'when non-admin user' do
      context 'WITHOUT assignment' do
        it 'cannot schedule an absence' do
          login :volunteer_without_assignment

          expect
        end
    end
  end
end
