class Volunteers::SessionsController < Devise::SessionsController
  include Accessible

  before_filter :check_user

end

