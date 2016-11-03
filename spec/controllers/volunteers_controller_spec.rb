require 'rails_helper'

RSpec.describe VolunteersController do
  let(:volunteer) { create :volunteer_with_assignment }
  let(:admin) { create :volunteer_with_assignment, admin: true }
  let(:resource) { create :volunteer }

  it_behaves_like 'an authenticated indexable resource'
  it_behaves_like 'an authenticated showable resource'

  describe 'GET #unassigned' do
    subject { get :unassigned }

    context 'non-admin user' do
      before { sign_in volunteer }

      it 'disallows the action' do
        expect(subject).to redirect_to root_path
      end
    end

    context 'admin user' do
      before { sign_in admin }

      it 'renders the unassigned template' do
        expect(subject).to render_template :unassigned
      end
    end
  end

  describe 'GET #assigned' do
    let(:region) { create :region }
    let(:alert) { 'Assignment worked' }

    subject do
      get :assign, { volunteer_id: volunteer.id, region_id: region.id }
    end

    before { sign_in volunteer }

    it 'redirects to action: :unassigned' do
      expect(subject).to redirect_to unassigned_volunteers_path(alert: alert)
    end
  end

  describe 'GET #shiftless' do
    subject { get :shiftless }

    context 'non-admin user' do
      before { sign_in volunteer }

      it 'disallows the action' do
        expect(subject).to redirect_to root_path
      end
    end

    context 'admin user' do
      before { sign_in admin }

      it 'renders the index template' do
        expect(subject).to render_template :index
      end
    end
  end

  describe 'GET #active' do
    subject { get :active }

    before { sign_in volunteer }

    it 'renders the index template' do
      expect(subject).to render_template :index
    end
  end

  describe 'GET #inactive' do
    subject { get :inactive }

    before { sign_in volunteer }

    it 'renders the index template' do
      expect(subject).to render_template :index
    end
  end

  describe 'GET #need_training' do
    subject { get :need_training }

    before { sign_in volunteer }

    it 'renders the index template' do
      expect(subject).to render_template :index
    end
  end

  describe 'GET #index' do
    subject { get :index }

    before { sign_in volunteer }

    it 'renders the index template' do
      expect(subject).to render_template :index
    end
  end

  describe 'GET #show' do
    subject { get :show, id: volunteer.id }

    before { sign_in volunteer }

    it 'renders the show template' do
      expect(subject).to render_template :show
    end
  end

  describe 'DELETE #destroy' do
    let(:referrer) { 'http://www.hadron-collider.pow' }

    subject { delete :destroy, id: volunteer.id }

    before do
      allow(request).to receive(:referrer) { referrer }
      sign_in volunteer
    end

    it 'redirects to the referrer' do
      expect(subject).to redirect_to referrer
    end
  end

  describe 'GET #new' do
    subject { get :new }

    before { sign_in volunteer }

    it 'renders the new template' do
      expect(subject).to render_template :new
    end
  end

  describe 'POST #create' do
    let(:new_volunteer) { build :volunteer }
    let(:valid_params) do
      {
        volunteer: {
          email: new_volunteer.email,
          password: new_volunteer.password,
          password_confirmation: new_volunteer.password_confirmation,
          requested_region_id: 1
        }
      }
    end

    subject { post :create, valid_params }

    before { sign_in admin }

    it 'renders the index template' do
      expect(subject).to render_template :index
    end
  end

  describe 'GET #edit' do
    subject do
      get :edit, { id: volunteer.id }
    end

    before { sign_in volunteer }

    it 'renders the edit template' do
      expect(subject).to render_template :edit
    end
  end

  describe 'PUT #update' do
    let(:name) { 'Mister Mxyzptlk' }
    let(:valid_params) do
      {
        id: volunteer.id,
        volunteer: {
          name: name
        }
      }
    end

    subject { put :update, valid_params }

    before { sign_in volunteer }

    it 'renders the index template' do
      expect(subject).to render_template :index
    end
  end

  describe 'GET #switch_user' do
    subject do
      get :switch_user, { volunteer_id: volunteer.id }
    end

    context 'non-admin user' do
      before { sign_in volunteer }

      it 'disallows the action' do
        expect(subject).to redirect_to root_path
      end
    end

    context 'admin user' do
      before do
        volunteer.update_attribute(:waiver_signed, true)
        sign_in admin
      end

      it 'renders the home template' do
        expect(subject).to render_template :home
      end
    end
  end

  describe 'GET #region_admin' do
    subject { get :region_admin }

    before { sign_in volunteer }

    it 'renders the region_admin template' do
      expect(subject).to render_template :region_admin
    end
  end

  describe 'GET #stats' do
    subject { get :stats }

    context 'non-admin user' do
      before { sign_in volunteer }

      it 'disallows the action' do
        expect(subject).to redirect_to root_path
      end
    end

    context 'admin user' do
      before { sign_in admin }

      it 'renders the stats template' do
        expect(subject).to render_template :stats
      end
    end
  end

  describe 'GET #waiver' do
    subject { get :waiver }

    before { sign_in volunteer }

    it 'renders the waiver template' do
      expect(subject).to render_template :waiver
    end
  end

  describe 'GET #sign_waiver' do
    subject do
      get :sign_waiver, { accept: '1' }
    end

    before { sign_in volunteer }

    it 'renders the home template' do
      expect(subject).to render_template :home
    end
  end

  describe 'GET #knight' do
    subject do
      get :knight, { volunteer_id: volunteer.id }
    end

    context 'non-admin user' do
      before { sign_in volunteer }

      it 'disallows the action' do
        expect(subject).to redirect_to root_path
      end
    end

    context 'admin user' do
      before { sign_in admin }

      it 'renders the knight template' do
        # TODO: fails with undef ar or meth `admin` in controller.
        # Should be `admin_only`? Which is not a route. Or, `admin_only`
        # should be `admin`?
        expect(subject).to render_template :knight
      end
    end
  end

  describe 'GET #reactivate' do
    subject do
      get :reactivate, { id: volunteer.id }
    end

    before { sign_in admin }

    it 'renders the index template' do
      expect(subject).to render_template :index
    end
  end

  describe 'GET #home' do
    subject { get :home }

    before do
      volunteer.update_attribute(:waiver_signed, true)
      sign_in volunteer
    end

    it 'renders the home template' do
      expect(subject).to render_template :home
    end
  end
end
