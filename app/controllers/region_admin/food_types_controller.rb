module RegionAdmin
  class FoodTypesController < ApplicationController
    before_filter :authenticate_volunteer!
    before_filter :authorize_region_admin!

    def index
      @food_types = available_food_types

      respond_to do |format|
        format.html
        format.json { render json: @food_types.to_json }
      end
    end

    def new
      @food_type         = FoodType.new
      @available_regions = available_regions

      session[:my_return_to] = request.referer
    end

    def create
      context = RegionAdmin::CreateFoodType.call(
        volunteer: current_volunteer,
        params:    params[:food_type]
      )

      if context.success?
        flash[:notice] = 'Created successfully.'
        redirect_to session[:my_return_to].presence || region_admin_food_types_url
      else
        @food_type         = context.food_type
        @available_regions = available_regions

        flash.now[:alert] = 'There were errors saving the Food Type.'
        render :new
      end
    end

    def edit
      @food_type         = FoodType.find(params[:id])
      @available_regions = available_regions

      authorize!(:update, @food_type)

      session[:my_return_to] = request.referer
    end

    def update
      context = RegionAdmin::UpdateFoodType.call(
        volunteer:    current_volunteer,
        food_type_id: params[:id],
        params:       params[:food_type]
      )

      if context.success?
        flash[:notice] = 'Updated successfully.'
        redirect_to session[:my_return_to].presence || region_admin_food_types_url
      else
        @food_type = context.food_type

        flash.now[:alert] = 'There were errors saving the Food Type.'
        render :edit
      end
    end

    def destroy
      context = RegionAdmin::DeleteFoodType.call(
        volunteer:    current_volunteer,
        food_type_id: params[:id]
      )

      if context.success?
        flash[:notice] = 'Deleted successfully.'
      else
        flash[:alert] = 'There were errors deleting the Food Type.'
      end

      redirect_to(request.referrer)
    end

    private

    def available_food_types
      if current_volunteer.super_admin?
        FoodType.accessible_by(current_ability).active
      else
        FoodType.accessible_by(current_ability).active.regional(available_regions.map(&:id))
      end
    end

    def available_regions
      if current_volunteer.super_admin?
        Region.all
      else
        current_volunteer.assignments.collect{ |a| a.admin ? a.region : nil }.compact
      end
    end

    def authorize_region_admin!
      return if region_admin?
      redirect_unauthorized
    end

    def region_admin?
      current_volunteer.any_admin?
    end

    def redirect_unauthorized
      redirect_to root_url, alert: 'Unauthorized'
    end
  end
end
