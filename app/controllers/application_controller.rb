class ApplicationController < ActionController::Base
  protect_from_forgery

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
end
