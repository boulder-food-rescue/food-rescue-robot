class ScaleTypesController < ApplicationController
  before_filter :authenticate_volunteer!

  def index
    region_ids = current_volunteer.region_ids
    @scale_types = ScaleType.where("region_id IN (#{region_ids.join(",")})")
    respond_to do |format|
      format.json { render json: @scale_types.to_json }
      format.html { render :index }
    end
  end

  def destroy
    @l = ScaleType.find(params[:id])
    return unless check_permissions(@l)
    @l.active = false
    @l.save
    redirect_to(request.referrer)
  end

  def new
    @scale_type = ScaleType.new
    @scale_type.region_id = params[:region_id]
    @scale_type.weight_unit = 1
    @action = "create"
    return unless check_permissions(@scale_type)
    session[:my_return_to] = request.referrer
    render :new
  end

  def create
    @scale_type = ScaleType.new(params[:scale_type])
    return unless check_permissions(@scale_type)
    if @scale_type.save
      flash[:notice] = "Created successfully."
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:notice] = "New scale didn't save."
      render :new
    end
  end

  def edit
    @scale_type = ScaleType.find(params[:id])
    return unless check_permissions(@scale_type)
    @action = "update"
    session[:my_return_to] = request.referrer
    render :edit
  end

  def update
    @scale_type = ScaleType.find(params[:id])
    return unless check_permissions(@scale_type)
    if @scale_type.update_attributes(params[:scale_type])
      flash[:notice] = "Updated successfully."
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:notice] = "Scale update didn't go through."
      render :edit
    end
  end

  def check_permissions(l)
    unless current_volunteer.super_admin? or (current_volunteer.admin_region_ids.include? l.region_id) 
      flash[:notice] = "Unauthorized to edit scales in that way."
      redirect_to(root_path)
      return false
    end
    return true
  end
end
