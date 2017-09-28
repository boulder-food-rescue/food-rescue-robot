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

      it 'responds with success' do
        subject
        expect(response.status).to eq 200
      end

      it 'renders the unassigned template' do
        expect(subject).to render_template :unassigned
      end

      context 'setting instance variables' do
        let(:assigned_volunteer) { volunteer }
        let(:unassigned_volunteers) { create_list :volunteer, 2 }
        let(:unassigned_vol1) { unassigned_volunteers.first }
        let(:region_id) { admin.admin_region_ids.first }
        let(:volunteers) { assigns(:volunteers) }

        before do
          assigned_volunteer
          unassigned_volunteers
        end

        describe '@volunteers' do
          context 'volunteers without assignments' do
            it 'includes the volunteers' do
              subject
              expect(volunteers).to match_array unassigned_volunteers
            end

            context 'without requested_region_id' do
              it 'includes the volunteer' do
                unassigned_vol1.update_attribute(:requested_region_id, nil)

                subject
                expect(volunteers).to include unassigned_vol1
              end
            end

            context 'with requested_region_id of logged-in admin' do
              before do
                unassigned_vol1.requested_region_id = region_id
                unassigned_vol1.save
              end

              it 'includes the volunteer' do
                subject
                expect(volunteers).to include unassigned_vol1
              end
            end
          end

          context 'volunteers with assignments' do
            it 'does _not_ include the volunteer' do
              subject
              expect(volunteers).not_to include assigned_volunteer
            end
          end
        end

        describe '@header' do
          let(:header) { 'Unassigned Volunteers' }

          it 'sets it' do
            subject
            expect(assigns(:header)).to eq header
          end
        end
      end
    end
  end

  describe 'GET #assigned' do
    let(:region) { create :region }
    let(:alert) { 'Assignment worked' }
    let(:params) do
      {
        volunteer_id: volunteer.id,
        region_id: region.id
      }
    end
    let(:welcome_params) { params.merge(send_welcome_email: '1') }
    let(:region_id) { volunteer.regions.first.id }
    let(:unassign_params) { params.merge(unassign: true, region_id: region_id) }

    context 'logged in user is an assigned volunteer' do
      before { sign_in volunteer }

      subject { get :assign, welcome_params }

      it 'redirects to action: :unassigned' do
        expect(subject).to redirect_to unassigned_volunteers_path(alert: alert)
      end

      it 'creates an assignment with the volunteer and region' do
        subject
        assignment = Assignment.where(volunteer_id: volunteer.id,
                                      region_id: region.id).first

        expect(volunteer.assignments).to include assignment
      end

      it 'calls for generating a welcome email' do
        expect(Notifier).to receive(:region_welcome_email)
        subject
      end

      it 'sends a welcome email' do
        expect_any_instance_of(Mail::Message).to receive(:deliver)
        subject
      end

      context 'a welcome email does not need to be sent' do
        it 'does _not_ call for sending a welcome email' do
          expect_any_instance_of(Mail::Message).not_to receive(:deliver)
          get :assign, params
        end
      end

      context 'params[:unassign] is present' do
        it 'deletes the assignment' do
          expect(volunteer.assignments.count).to eq 1
          get :assign, unassign_params
          expect(volunteer.assignments).to be_empty
        end
      end
    end

    context 'logged in user has not yet been assigned by region admin' do
      let(:unassigned_volunteer) { create :volunteer }

      before { sign_in unassigned_volunteer }

      it 'redirects to sign in' do
        get :assign, params.merge(volunteer_id: unassigned_volunteer.id)
        expect(subject).to redirect_to new_volunteer_session_path
      end
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
    it 'assigns header' do
      subject
      expect(assigns(:header)).to_not be_nil
    end
    it 'assigns volunteer, html' do
      subject
      expect(assigns(:volunteers)).to eq([volunteer])
    end
    it 'assigns volunteer, json' do
      get :index, format: :json
      expect(assigns(:volunteers)).to eq([volunteer])
      response_json = JSON.parse(response.body)
      expect(response_json.length).to eq(1)
      expect(response_json[0]['email']).to eq(volunteer.email)
      expect(response_json[0]['name']).to eq(volunteer.name)
      expect(response_json[0]['phone']).to eq(volunteer.phone)
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

  describe 'GET #region_admin as volunteer' do
    subject { get :region_admin }

    before { sign_in volunteer }

    it 'renders the region_admin template' do
      expect(subject).to render_template :region_admin
    end
    it 'adds regions' do
      subject
      expect(assigns(:regions)).to_not be_nil
      expect(assigns(:regions).count).to eq(1)
    end
    it 'my_admin_volunteers is empty by default' do
      subject
      expect(assigns(:my_admin_volunteers)).to eq([])
    end
  end

  describe 'GET #region_admin as admin' do
    subject { get :region_admin }

    before { sign_in admin }

    it 'renders the region_admin template' do
      expect(subject).to render_template :region_admin
    end
    it 'adds regions' do
      subject
      expect(assigns(:regions)).to_not be_nil
      expect(assigns(:regions).count).to eq(1)
    end
    it 'my_admin_volunteers is empty by default' do
      subject
      expect(assigns(:my_admin_volunteers)).to eq([admin])
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

      it 'renders the knight template'
      # PENDING: fails with undef var or method `admin` in controller.
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
