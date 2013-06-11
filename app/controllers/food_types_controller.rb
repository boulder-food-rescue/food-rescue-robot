class FoodTypesController < ApplicationController
  before_filter :authenticate_volunteer!

  def index
    @food_types = FoodType.where("region_id IN (#{Region.all_admin(current_volunteer).collect{ |r| r.id }.join(",")})")
    render :index
  end

  def destroy
    @l = FoodType.find(params[:id])
    return unless check_permissions(@l)
    @l.destroy
    redirect_to(request.referrer)
  end

  def new
    @food_type = FoodType.new
    @food_type.region_id = params[:region_id]
    @action = "create"
    return unless check_permissions(@food_type)
    session[:my_return_to] = request.referer
    render :new
  end

  def create
    @food_type = FoodType.new(params[:food_type])
    return unless check_permissions(@food_type)
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
    return unless check_permissions(@food_type)
    @action = "update"
    session[:my_return_to] = request.referer
    render :edit
  end

  def update
    @food_type = FoodType.find(params[:id])
    return unless check_permissions(@food_type)
    # can't set admin bits from CRUD controls
    if @food_type.update_attributes(params[:food_type])
      flash[:notice] = "Updated Successfully."
      unless session[:my_return_to].nil?
        redirect_to(session[:my_return_to])
      else
        index
      end
    else
      flash[:notice] = "Update failed :("
      render :edit
    end
  end

  def check_permissions(l)
    unless current_volunteer.super_admin? or (current_volunteer.admin_region_ids.include? l.region_id) or
      flash[:notice] = "Not authorized to create/edit/delete food_types for that region"
      redirect_to(root_path)
      return false
    end
    return true
  end

end 
