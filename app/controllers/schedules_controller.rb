class SchedulesController < ApplicationController
  active_scaffold :schedule do |conf|
    conf.columns[:day_of_week].form_ui = :select
    conf.columns[:day_of_week].options = {:options => [["Sunday",0],["Monday",1],["Tuesday",2],["Wednesday",3],["Thursday",4],["Friday",5],["Saturday",6]]}
    conf.columns[:time_start].description = "e.g., 1400"
    conf.columns[:time_stop].description = "e.g., 1600"
  end
end 
