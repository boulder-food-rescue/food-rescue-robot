module LocationsHelper

  def type_for_display location
    if location.donor? 
      return "Donor" 
    else
      return "Recipient"
    end
  end

  def readable_hours location
    str = ""
    if Webapp::Application.config.use_detailed_hours 
      str = readable_detailed_hours location
    else
      str = readable_simple_hours location
    end
    str
  end

  private 

    def readable_simple_hours loc
      loc.hours.gsub("\n","<br>").html_safe unless loc.hours.nil? 
    end

    def readable_detailed_hours location
      str = ''
      (0..6).each do |index|
        if location.open_on_day? index
          str += Date::DAYNAMES[index] + ' from ' + format_time(location.read_attribute('day'+index.to_s+'_start')) + 
            ' to ' + format_time(location.read_attribute('day'+index.to_s+'_end')) + '<br />'
        end
      end
      str.html_safe
    end

    def format_time t
      I18n.l t, :format => "%I:%M%p",  :locale => :"en"
    end

end