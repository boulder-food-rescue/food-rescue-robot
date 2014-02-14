class ApplicationController < ActionController::Base
  protect_from_forgery

  ActiveScaffold.set_defaults do |config|
    config.security.current_user_method = :current_volunteer
  end
  
  layout :layout_by_resource

  protected
  
    def layout_by_resource
      if devise_controller?
        "custom_devise"
      else
        "application"
      end
    end

  private

    # add in the variables needed by the form partial for schedules and logs
    def set_vars_for_form region
      @volunteers = Volunteer.all_for_region(region.id).collect{ |v| [v.name,v.id] }
      @donors = Location.donors.where(:region_id=>region.id).collect{ |d| [d.name,d.id] }
      @recipients = Location.recipients.where(:region_id=>region.id).collect{ |r| [r.name,r.id] }
      @food_types = FoodType.regional(region.id).collect{ |ft| [ft.name,ft.id] }
      @transport_types = TransportType.all.collect{ |tt| [tt.name,tt.id] }
      @scale_types = ScaleType.regional(region.id).collect{ |st| [st.name,st.weight_unit,st.id] }
    end

end
