module Accessible

  def check_user
    puts "GETE HERERE1"
    #binding.pry
    puts "s4d"
    if current_donor
      flash.clear
      # if you have rails_admin. You can redirect anywhere really
      redirect_to(rails_donor.dashboard_path) && return
    elsif current_volunteer
      flash.clear
      puts "GETE HERERE"
      # The authenticated root path can be defined in your routes.rb in: devise_scope :user do...
      redirect_to(home_volunteers_path) && return
    end
  end
end