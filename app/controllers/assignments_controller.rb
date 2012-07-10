class AssignmentsController < ApplicationController
  active_scaffold :assignment do |conf|
    conf.columns = [:admin,:region,:volunteer]
    conf.columns[:region].form_ui = :select
    conf.columns[:volunteer].form_ui = :select
  end
end 
