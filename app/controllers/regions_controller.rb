class RegionsController < ApplicationController
  before_filter :authenticate_volunteer!, :except => [:recipients, :request_rescue]

  def index
    authorize! :read, Region
    @regions = Region.accessible_by(current_ability)
  end

  def new
    @region = Region.new
    authorize! :create, @region
  end

  def create
    @region = Region.new(params[:region])
    authorize! :create, @region

    if @region.save
      flash[:notice] = 'Created successfully'
      redirect_to regions_url
    else
      flash.now[:error] = "Create failed"
      render :new
    end
  end

  def edit
    @region = Region.find(params[:id])
    authorize! :update, @region
  end

  def update
    @region = Region.find(params[:id])
    authorize! :update, @region

    if @region.update_attributes(params[:region])
      flash.now[:notice] = 'Updated successfully'
      redirect_to edit_region_url(@region)
    else
      flash.now[:error] = 'Update failed'
      render :edit
    end
  end

  def destroy
    region = Region.find(params[:id])
    authorize! :destroy, region
    region.destroy

    flash.now[:notice] = 'Deleted successfully'
    redirect_to regions_url
  end

  def recipients
    @region = Region.find(params[:id])
    @locations = Location.recipients.where(region_id: @region.id)
    @json = @locations.to_gmaps4rails do |location, marker|
      marker.infowindow render_to_string(template: "locations/_details.html", layout: nil, locals: { location: location}).html_safe
      marker.picture({
        "picture" => location.open? ? 'http://maps.google.com/mapfiles/marker_green.png' : 'http://maps.google.com/mapfiles/marker.png',
        "width" =>  '32', "height" => '37'
      })
    end
  end

  def request_rescue
    @region = Region.find(params[:id])
    set_vars_for_form @region
    @schedule = Schedule.new
    @time_options = []
    ['am','pm'].each do |ampm|
      (1..12).each do |hour|
        ['00','30'].each do |min|
          @time_options << hour.to_s+':'+min+' '+ampm
        end
      end
    end
  end
end
