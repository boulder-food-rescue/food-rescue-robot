# frozen_string_literal: true

RSpec.shared_examples_for 'an authenticated indexable resource' do
  context 'when not authenticated' do
    context 'GET #index' do
      it 'should redirect to sign in' do
        get :index
        expect(response).to redirect_to(new_volunteer_session_path)
      end
    end
  end

  context 'when authenticated' do
    before { sign_in volunteer }

    context 'GET #index' do
      it 'should not redirect to sign in' do
        get :index
        expect(response).not_to redirect_to(new_volunteer_session_path)
      end
    end
  end
end
