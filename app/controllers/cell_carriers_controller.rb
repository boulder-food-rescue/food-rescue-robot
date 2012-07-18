class CellCarriersController < ApplicationController
  active_scaffold :cell_carrier do |conf|
    conf.columns = [:name,:format]
  end
end 
