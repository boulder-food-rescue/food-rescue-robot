class LocationAdmins::RegistrationController < Devise::RegistrationsController
  def new
    @location_admin = LocationAdmin.new
    @regions = Region.all
    render 'location_admins/new'
  end

  def create
    @location_admin = LocationAdmin.new(params[:location_admin])
    #@location_admin.location_associations.each { |assignment| assignment.admin = false }
    if @location_admin.save
      flash[:notice] = 'Created successfully.'
      redirect_to new_location_admin_session_path
    else
      flash[:error] = "Didn't save successfully :(. #{@location_admin.errors.full_messages.to_sentence}"
      render 'location_admins/new'
    end
  end

  def update
    super
  end
end