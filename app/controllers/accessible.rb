module Accessible

  def check_user
    if current_location_admin
      flash.clear
      # if you have rails_admin. You can redirect anywhere really
      redirect_to(home_location_admins_path) && return
    elsif current_volunteer
      flash.clear
      # The authenticated root path can be defined in your routes.rb in: devise_scope :user do...
      redirect_to(home_volunteers_path) && return
    end
  end
end