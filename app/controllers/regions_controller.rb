class RegionsController < ApplicationController
  before_filter :authenticate_volunteer!, :except => [:recipients, :request_rescue]
  before_filter :super_admin_only, :except => [:recipients, :request_rescue]

  def super_admin_only
    redirect_to(root_path) unless current_volunteer.super_admin?
  end

  def index
    @regions = Region.all
    @header = "All Regions"
    render :index
  end

  def edit
    @region = Region.find(params[:id])
    render :edit
  end

  def update
    @region = Region.find(params[:id])
    if @region.update_attributes(params[:region])
      flash[:notice] = "Updated Successfully."
      index
    else
      flash[:notice] = "Update failed :("
      render :edit
    end
  end

  def new
    @region = Region.new
    render :new
  end

  def create
    @region = Region.new(params[:region])
    if @region.save
      flash[:notice] = "Created successfully."
      index
    else
      flash[:notice] = "Didn't save successfully :("
      render :new
    end
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

  def destroy
    @r = Region.find(params[:id])
    @r.destroy
    index
  end


end 
