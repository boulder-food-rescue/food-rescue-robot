# frozen_string_literal: true

class SessionsController < Devise::SessionsController
  respond_to :json

  def create
    respond_to do |format|
      format.html {
        super
      }
      format.json {
        user = Volunteer.find_for_database_authentication(:email => params[:email])
        return invalid_login_attempt unless user
        user.ensure_authentication_token
        if user.valid_password?(params[:password])
          user.reset_authentication_token
          user.reload
          render :json => { :authentication_token => user.authentication_token }, success: true, status: :created
        else
          invalid_login_attempt
        end
      }
    end
  end

  def destroy
    respond_to do |format|
      format.html {
        super
      }
      format.json {
        user = Volunteer.find_by_authentication_token(params[:authentication_token])
        if user
          user.reset_authentication_token
          render :json => { :message => 'Session deleted.' }, :success => true, :status => 204
        else
          render :json => { :message => 'Invalid token.' }, :status => 404
        end
      }
    end
  end

  protected

  def invalid_login_attempt
    warden.custom_failure!
    render json: { success: false, message: 'Error with your login or password' }, status: 401
  end
end
