class LocationAdmins::SessionsController < Devise::SessionsController
  include Accessible
  before_filter :check_user
  skip_before_filter :check_user, only: :destroy

end

