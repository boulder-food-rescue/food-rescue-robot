class RegionsController < ApplicationController

  active_scaffold :region do |conf|
    conf.columns = [:name,:address,:lat,:lng,:notes,:website,:handbook_url,:prior_lbs_rescued,:prior_num_pickups]
    conf.update.columns = [:name,:address,:lat,:lng,:notes,:website,:handbook_url,:prior_lbs_rescued,
                           :prior_num_pickups,:twitter_key,:twitter_secret,:twitter_token,:twitter_token_secret,
                           :twitter_last_poundage,:twitter_last_timestamp]
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
end 