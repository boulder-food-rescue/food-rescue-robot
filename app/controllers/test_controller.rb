class TestController < ApplicationController
  def schedule
  end
  
  def take
    l = Schedule.find(params[:id])
    l.volunteer = current_volunteer
    l.save
    index
  end
end
