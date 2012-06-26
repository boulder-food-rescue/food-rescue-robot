class ApplicationController < ActionController::Base
  protect_from_forgery

  ActiveScaffold.set_defaults do |config|
    config.security.current_user_method = :current_volunteer
  end
end
