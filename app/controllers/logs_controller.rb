class LogsController < ApplicationController
  active_scaffold :log do |conf|
    conf.columns[:transport].form_ui = :select
    conf.columns[:transport].label = "Transportation Used"
    conf.columns[:transport].options = {:options => [["Bike","Bike"],["Car","Car"],["Foot","Foot"]]}
    conf.columns[:weighed_by].form_ui = :select
    conf.columns[:weighed_by].options = {:options => [["Bathroom Scale","Bathroom Scale"],["Floor Scale","Floor Scale"],["Guesstimate","Guesstimate"]]}
    conf.columns[:weight].description = "e.g., '42', in pounds"
    conf.columns[:num_reminders].form_ui = :select
    conf.columns[:num_reminders].label = "Reminders Sent"
    conf.columns[:num_reminders].options = {:options => [[0,0],[1,1],[2,2],[3,3],[4,4]]}

  end
end 
