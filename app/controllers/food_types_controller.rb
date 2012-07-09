class FoodTypesController < ApplicationController
  active_scaffold :food_type do |conf|
    conf.columns = [:name]
  end
end 
