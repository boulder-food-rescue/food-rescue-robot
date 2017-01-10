class FoodTypesController < ApplicationController
  before_filter :authenticate_volunteer!

  def index
    authorize FoodType
    @food_types = policy_scope(FoodType)
    respond_to do |format|
      format.json { render json: @food_types.to_json }
      format.html { render :index }
    end
  end

  def destroy
    @l = FoodType.find(params[:id])
    authorize @l
    @l.active = false
    @l.save
    redirect_to(request.referrer)
  end

  def new
    @food_type = FoodType.new
    @food_type.region_id = params[:region_id]
    @action = "create"
    authorize @food_type
    session[:my_return_to] = request.referer
    render :new
  end

  def create
    @food_type = FoodType.new(params[:food_type])
    authorize @food_type
    if @food_type.save
      flash[:notice] = "Created successfully."
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:notice] = "Didn't save successfully :("
      render :new
    end
  end

  def edit
    @food_type = FoodType.find(params[:id])
    authorize @food_type
    @action = "update"
    session[:my_return_to] = request.referer
    render :edit
  end

  def update
    @food_type = FoodType.find(params[:id])
    authorize @food_type
    # can't set admin bits from CRUD controls
    if @food_type.update_attributes(params[:food_type])
      flash[:notice] = "Updated Successfully."
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:error] = "Update failed :("
      render :edit
    end
  end
end
