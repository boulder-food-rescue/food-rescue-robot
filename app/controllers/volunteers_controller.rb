class VolunteersController < ApplicationController
  active_scaffold :volunteer do |conf|
    #conf.list.sorting = {:name => 'ASC'}
    conf.columns[:is_disabled].label = "Account Deactivated"
    conf.columns[:transport].form_ui = :select
    conf.columns[:transport].label = "Preferred Transportation"
    conf.columns[:transport].options = {:options => [["Bike","Bike"],["Car","Car"],["Foot","Foot"]]}
    conf.columns[:preferred_contact].form_ui = :select
    conf.columns[:preferred_contact].options = {:options => [["Email","Email"],["Phone","Phone"],["Text","Text"]]}
  end

  def home

  end
end 
