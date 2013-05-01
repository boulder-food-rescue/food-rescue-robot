class RegionsController < ApplicationController
  before_filter :authenticate_volunteer!, :except => [:recipients]

  active_scaffold :region do |conf|
    conf.columns = [:logo,:name,:title,:tagline,:address,:phone,:tax_id,:lat,:lng,:notes,:website]
    conf.update.columns = [:logo,:name,:title,:tagline,:address,:phone,:tax_id,:lat,:lng,:notes,:website,:handbook_url,:prior_lbs_rescued,
                           :prior_num_pickups,:twitter_key,:twitter_secret,:twitter_token,:twitter_token_secret,:welcome_email_text,:splash_html]
    # if marking isn't enabled it creates errors on delete :(
    conf.actions.add :mark
  end
  def create_authorized?
    current_volunteer.super_admin?
  end
  def update_authorized?(record=nil)
    current_volunteer.super_admin?
  end
  def delete_authorized?(record=nil)
    current_volunteer.super_admin?
  end

  def recipients
    @region = Region.find(params[:id])
    @locations = Location.recipients.where(:region_id=>@region.id)
    @json = @locations.to_gmaps4rails do |loc, marker|
      marker.infowindow render_to_string(:template => "locations/_map_infowindow.html", :layout=>nil, :locals => { :loc => loc}).html_safe
      marker.picture({
        "picture" => loc.open? ? 'http://maps.google.com/mapfiles/marker_green.png' : 'http://maps.google.com/mapfiles/marker.png',
        "width" =>  '32', "height" => '37'
      })
    end
  end

end 
