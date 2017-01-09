require 'food_robot'

class ApplicationController < ActionController::Base

  protect_from_forgery with: :null_session
  after_filter :setup_headers
  before_filter :authenticate_user_from_token!

  respond_to :html, :json

  def setup_headers
    headers['Access-Control-Allow-Origin'] = '*'
    headers['Access-Control-Allow-Methods'] = 'POST, PUT, DELETE, GET, OPTIONS'
    headers['Access-Control-Request-Method'] = '*'
    headers['Access-Control-Allow-Headers'] = 'Origin, X-Requested-With, Content-Type, Accept, Authorization'
  end

  ActiveScaffold.set_defaults do |config|
    config.security.current_user_method = :current_volunteer
  end

  rescue_from CanCan::AccessDenied do
    respond_to do |format|
      format.json { head :forbidden }
      format.html do
        flash[:error] = "You are not authorized to do that"

        begin
          redirect_to :back
        rescue ActionController::RedirectBackError
          redirect_to root_path
        end
      end
    end
  end

  alias_method :current_user, :current_volunteer

  layout :layout_by_resource

  protected

    def layout_by_resource
      if devise_controller?
        "custom_devise"
      else
        "application"
      end
    end

  private

  # add in the variables needed by the form partial for schedules and logs
  def set_vars_for_form(region)
    @volunteers = Volunteer.all_for_region(region.id).collect{ |v| [v.name,v.id] }
    @donors = Location.donors.where(:region_id=>region.id).collect{ |d| [d.name,d.id] }
    @recipients = Location.recipients.where(:region_id=>region.id).collect{ |r| [r.name,r.id] }
    @transport_types = TransportType.all.collect{ |tt| [tt.name,tt.id] }

    @food_types = region.food_types.collect { |food_type| [food_type.name, food_type.id] }
    @scale_types = region.scale_types.collect { |scale_type| ["#{scale_type.name} (#{scale_type.weight_unit})", scale_type.id] }

    @regions = Region.all
  end

  # Token Authentication:
  # https://gist.github.com/josevalim/fb706b1e933ef01e4fb6
  def authenticate_user_from_token!
    user_email = params["volunteer_email"]
    return if user_email.nil?

    user = Volunteer.find_by_email(user_email)
    token = params["volunteer_token"]
    return if token.nil?
    if user and Devise.secure_compare(user.authentication_token,token)
      sign_in user, store: false
    end
  end


end
