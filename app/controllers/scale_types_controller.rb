class ScaleTypesController < ApplicationController
  before_filter :authenticate_volunteer!

  def index
    @scale_types = ScaleType.accessible_by(current_ability)
    respond_to do |format|
      format.json { render json: @scale_types.to_json }
      format.html { render :index }
    end
  end

  def destroy
    @l = ScaleType.find(params[:id])
    authorize! :destroy, ScaleType
    @l.active = false
    @l.save
    redirect_to(request.referrer)
  end

  def new
    @scale_type = ScaleType.new
    @scale_type.region_id = params[:region_id]
    @scale_type.weight_unit = 1
    @action = "create"
    authorize! :create, @scale_type
    session[:my_return_to] = request.referrer
    render :new
  end

  def create
    @scale_type = ScaleType.new(params[:scale_type])
    authorize! :create, @scale_type
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
    authorize! :update, @scale_type
    @action = "update"
    session[:my_return_to] = request.referrer
    render :edit
  end

  def update
    @scale_type = ScaleType.find(params[:id])
    authorize! :update, @scale_type
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
end
