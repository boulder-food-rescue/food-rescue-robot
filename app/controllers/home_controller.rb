class HomeController < ApplicationController
  def welcome
    today = Date.today
    
    #Upcoming pickup list
    @upcoming_pickups = Log.where(:when => today...(today + 7)).where(:volunteer_id => current_volunteer)
    
    #To Do Pickup Reports
    @to_do_reports = Log.where('"logs"."when" <= ?', today).where("weight IS NULL").where(:volunteer_id => current_volunteer)
    
    #Last 10 pickups
    @last_ten_pickups = Log.where(:volunteer_id => current_volunteer).where("weight IS NOT NULL").order('"logs"."when" DESC').limit(10)
    
    #Pickup Stats
    @completed_pickup_count = Log.count(:conditions => {:volunteer_id => current_volunteer})
    @total_food_rescued = Log.where(:volunteer_id => current_volunteer).where("weight IS NOT NULL").sum(:weight)
    completed_pickups = Log.where(:volunteer_id => current_volunteer).where("weight IS NOT NULL")
    @dis_traveled = 0.0
    completed_pickups.each do |pickup|
      donor = Location.find(pickup.schedule.donor_id)
      recipient = Location.find(pickup.schedule.recipient_id)
      if donor.lng != nil && donor.lat != nil && recipient.lng != nil && recipient.lat != nil
        radius = 6371.0
        dLat = (donor.lat - recipient.lat) * Math::PI / 180.0
        dLon = (donor.lng - recipient.lng) * Math::PI / 180.0
        lat1 = recipient.lat * Math::PI / 180.0
        lat2 = donor.lat * Math::PI / 180.0
        
        a = Math.sin(dLat/2) * Math.sin(dLat/2) + Math.sin(dLon/2) * Math.sin(dLon/2) * Math.cos(lat1) * Math.cos(lat2)
        c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a))
        @dis_traveled += radius * c
      end
    end
    
    #Food Collected Graphs
    running_total = 0.0
    v_running_total = 0.0
    time = Time.now
    current_month = time.month
    current_year = time.year
    current_day = time.day
    food_per_day = []
    v_food_per_day = []
    food_per_month = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
    v_food_per_month = [0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0,0.0]
    start_date = Date.new(2012, 6, 26)
    range = Date.today - start_date
    for i in 0..range
      start_date += 1
      total = Log.where(:when => start_date).where("weight IS NOT NULL").sum(:weight)
      v_total = Log.where(:when => start_date).where("weight IS NOT NULL").where(:volunteer_id => current_volunteer).sum(:weight)
      if total != nil
        running_total += total
        food_per_month[start_date.month - 1] += total
      end
      if v_total != nil
        v_running_total += v_total
        v_food_per_month[start_date.month - 1] += v_total
      end
      food_per_day << running_total
      v_food_per_day << v_running_total
    end
    
    @food_chart_day = LazyHighCharts::HighChart.new('area') do |f|
      f.options[:chart][:defaultSeriesType] = "area"
      f.options[:chart][:plotBackgroundColor] = nil
      f.options[:title][:text] = "Food Rescued Since June 26, 2012"
      f.options[:xAxis][:title] = {:enabled => true, :text => "Days Since 06/26/2012"}
      f.options[:yAxis][:title][:text] = "lbs of food"
      f.plot_options(:area => {
        :pointStart => 0,
        :marker => {
          :enabled => false,
          :symbol => 'circle',
          :radius => 2,
          :states => {
            :hover => {
              :enabled => true
            }
          }
        }
      })
      f.series(:name=>'BFR Pounds of Food Rescued', :data=> food_per_day)
      f.series(:name=>'Your Pounds of Food Rescued', :data=> v_food_per_day)
    end
    
    month_labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    for i in 1..current_month
      month_labels = month_labels.push(month_labels.shift)
      food_per_month = food_per_month.push(food_per_month.shift)
      v_food_per_month = v_food_per_month.push(v_food_per_month.shift)
    end
    
    @food_chart_month = LazyHighCharts::HighChart.new('column') do |f|
      f.options[:chart][:defaultSeriesType] = "column"
      f.options[:chart][:plotBackgroundColor] = nil
      f.options[:title][:text] = "Food Rescued By Month"
        f.options[:xAxis] = {
        :plot_bands => "none",
        :title=>{:text=>"Month"},
        :categories => month_labels}
      f.options[:yAxis][:title][:text] = "lbs of food"
      f.series(:name=>'BFR Pounds of Food Rescued', :data=> food_per_month)
      f.series(:name=>'Your Pounds of Food Rescued', :data=> v_food_per_month)
    end
  end
end
