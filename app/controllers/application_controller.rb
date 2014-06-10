    class ApplicationController < ActionController::Base
  protect_from_forgery

  before_filter :authenticate_user_from_token!

  respond_to :html, :json

  ActiveScaffold.set_defaults do |config|
    config.security.current_user_method = :current_volunteer
  end
  
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

  # Token Authentication:
  # https://gist.github.com/josevalim/fb706b1e933ef01e4fb6
  def authenticate_user_from_token!
    vol_email = params["auth_id"]
    return if vol_email.nil?
    vol = Volunteer.find_by_email(vol_email)
    token = params["auth_token"]
    return if token.nil?
    if vol and Devise.secure_compare(vol.auth_token,token)
      sign_in vol, store: false
    end
  end

  # add in the variables needed by the form partial for schedules and logs
  def set_vars_for_form region
    @volunteers = Volunteer.all_for_region(region.id).collect{ |v| [v.name,v.id] }
    @donors = Location.donors.where(:region_id=>region.id).collect{ |d| [d.name,d.id] }
    @recipients = Location.recipients.where(:region_id=>region.id).collect{ |r| [r.name,r.id] }
    @food_types = FoodType.regional(region.id).collect{ |ft| [ft.name,ft.id] }
    @transport_types = TransportType.all.collect{ |tt| [tt.name,tt.id] }
    @scale_types = ScaleType.regional(region.id).collect{ |st| ["#{st.name} (#{st.weight_unit})",st.id] }
    @regions = Region.all
  end

end
