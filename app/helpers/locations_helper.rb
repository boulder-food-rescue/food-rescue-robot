module LocationsHelper

  def readable_hours location
    readable_detailed_hours location
  end

  private 

    def readable_simple_hours loc
      loc.hours.gsub("\n","<br>").html_safe unless loc.hours.nil? 
    end

    def readable_detailed_hours location
      str = ''
      (0..6).each do |index|
        if location.open_on_day? index
          str += Date::ABBR_DAYNAMES[index] + ': ' + format_time(location.read_day_info('day'+index.to_s+'_start')) + 
            ' - ' + format_time(location.read_day_info('day'+index.to_s+'_end')) + '<br />'
        end
      end
      str.html_safe
    end

    def format_time t
      t.to_s(:clean_time)
    end

end
