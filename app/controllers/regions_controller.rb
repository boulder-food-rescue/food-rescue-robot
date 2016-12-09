class RegionsController < ApplicationController
  before_filter :authenticate_volunteer!, :except => [:recipients, :request_rescue]
  before_filter :super_admin_only, :except => [:recipients, :request_rescue, :edit, :update]

  def index
    @regions = Region.all
  end

  def new
    @region = Region.new
  end

  def create
    @region = Region.new(params[:region])

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

    unless current_volunteer.region_admin?(@region, false)
      return redirect_unauthorized
    end
  end

  def update
    @region = Region.find(params[:id])

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
    Region.find(params[:id]).destroy

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

  private

  def super_admin_only
    return if current_volunteer.super_admin?
    redirect_unauthorized
  end

  def redirect_unauthorized
    redirect_to root_path, error: "Sorry, you can't go there"
  end
end
