class RegionsController < ApplicationController
  before_filter :authenticate_volunteer!, :except => [:recipients, :request_rescue]
  before_filter :skip_authorization, only: [:recipients, :request_rescue]

  def index
    authorize Region
    @regions = policy_scope(Region)
  end

  def new
    @region = Region.new
    authorize @region
  end

  def create
    @region = Region.new(params[:region])
    authorize @region

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
    authorize @region

    unless current_volunteer.region_admin?(@region, false)
      return redirect_unauthorized
    end
  end

  def update
    @region = Region.find(params[:id])
    authorize @region

    unless current_volunteer.region_admin?(@region, false)
      return redirect_unauthorized
    end

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
    authorize region
    region.destroy

    flash.now[:notice] = 'Deleted successfully'
    redirect_to regions_url
  end

  def recipients
    @region = Region.find(params[:id])
    @locations = Location.recipients.where(:region_id=>@region.id)
    @json = @locations.to_gmaps4rails do |loc, marker|
      marker.infowindow render_to_string(:template => "locations/_details.html", :layout=>nil, :locals => { :loc => loc}).html_safe
      marker.picture({
        "picture" => loc.open? ? 'http://maps.google.com/mapfiles/marker_green.png' : 'http://maps.google.com/mapfiles/marker.png',
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
