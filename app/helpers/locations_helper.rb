module LocationsHelper

  def type_for_display location
    if location.donor? 
      return "Donor" 
    else
      return "Recipient"
    end
  end

end