class HomeController < ApplicationController
  def welcome
    today = Date.today
    @upcoming_pickups = Log.where(:when => today...(today + 7))
    @to_do_reports = Log.where('"logs"."when" <= ?', today).where("weight IS NULL")
  end
end
