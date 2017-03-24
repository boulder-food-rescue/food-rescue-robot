class FoodTypesController < ApplicationController
  before_filter :authenticate_volunteer!

  def index
    @food_types = FoodType.accessible_by(current_ability)
    respond_to do |format|
      format.json { render json: @food_types.to_json }
      format.html { render :index }
    end
  end

  def destroy
    food_type = FoodType.find(params[:id])
    authorize! :destroy, food_type
    food_type.active = false
    food_type.save
    redirect_to(request.referrer)
  end

  def new
    @food_type = FoodType.new
    @food_type.region_id = params[:region_id]
    @action = 'create'
    authorize! :create, @food_type
    session[:my_return_to] = request.referer
    render :new
  end

  def create
    @food_type = FoodType.new(params[:food_type])
    authorize! :create, @food_type
    if @food_type.save
      flash[:notice] = 'Created successfully.'
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
    authorize! :update, @food_type
    @action = 'update'
    session[:my_return_to] = request.referer
    render :edit
  end

  def update
    @food_type = FoodType.find(params[:id])
    authorize! :update, @food_type
    # can't set admin bits from CRUD controls
    if @food_type.update_attributes(params[:food_type])
      flash[:notice] = 'Updated Successfully.'
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:error] = 'Update failed :('
      render :edit
    end
  end
end
