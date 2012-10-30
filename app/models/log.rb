class Log < ActiveRecord::Base
  belongs_to :schedule
  belongs_to :volunteer
  belongs_to :orig_volunteer, :foreign_key => "orig_volunteer_id", :class_name => "Volunteer"
  belongs_to :donor, :class_name => "Location", :foreign_key => "donor_id"
  belongs_to :recipient, :class_name => "Location", :foreign_key => "recipient_id"
  belongs_to :food_type
  belongs_to :transport_type
  belongs_to :region
  attr_accessible :schedule_id, :region_id, :volunteer_id, :donor_id, :recipient_id, :food_type_id, :transport_type_id, :description, :flag_for_admin, :notes, :num_reminders, :orig_volunteer_id, :transport, :weighed_by, :weight, :when

  after_save { |record| tweet(record) }

  def tweet(record)
    return true if record.region.nil? or record.region.twitter_key.nil?
    return true if record.weight.nil? or record.weight <= 0
    # only tweet if it's been an hour since the last one
    return true unless record.region.twitter_last_timestamp.nil? or (Time.now - record.region.twitter_last_timestamp) > 3600
    begin
      Twitter.configure do |config|
        config.consumer_key = record.region.twitter_key
        config.consumer_secret = record.region.twitter_secret
        config.oauth_token = record.region.twitter_token
        config.oauth_token_secret = record.region.twitter_token_secret
      end
      poundage = Log.where("weight IS NOT NULL AND weight > 0 AND region_id = ?",region.id).collect{ |l| l.weight }.sum
      poundage += record.region.prior_lbs_rescued
      last_poundage = region.twitter_last_poundage.nil? ? 0.0 : region.twitter_last_poundage
      if poundage <= last_poundage
        region.twitter_last_poundage = poundage
        region.save
        return true
      end
      t = "#{record.volunteer.name} picked up #{record.weight.round} lbs of food, bringing us to #{poundage.round} lbs of food rescued to date in #{record.region.name}."
      if record.donor.twitter_handle.nil?
        t += "Thanks to #{record.donor.name} for the donation!"
      else
        t += " Thanks to @#{record.donor.twitter_handle} for the donation!"
      end
      return true if t.length > 140
      Twitter.update(t)
      record.region.twitter_last_poundage = poundage
      record.region.twitter_last_timestamp = Time.now
      record.region.save
      flash[:notice] = "Tweeted: #{t}"
    rescue
      # Twitter update didn't work for some reason, but everything else seems to have...
    end
    return true
  end

end
