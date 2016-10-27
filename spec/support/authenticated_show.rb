RSpec.shared_examples_for 'an authenticated showable resource' do
  context 'when not authenticated' do
    context 'GET #show' do
      it 'should redirect to sign in' do
        get :show, id: resource.id
        expect(response).to redirect_to(new_volunteer_session_path)
      end
    end
  end

  context 'when authenticated' do
    before { sign_in volunteer }

    context 'GET #show' do
      it 'should have a 200 response code' do
        get :show, id: resource.id
        expect(response).to be_success
      end
    end
  end
end
