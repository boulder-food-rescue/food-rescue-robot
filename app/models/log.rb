class Log < ActiveRecord::Base
  belongs_to :schedule
  has_many :log_volunteers
  has_many :volunteers, :through => :log_volunteers,
           :conditions=>{"log_volunteers.active"=>true}
  belongs_to :donor, :class_name => "Location", :foreign_key => "donor_id"
  belongs_to :recipient, :class_name => "Location", :foreign_key => "recipient_id"
  belongs_to :food_type
  belongs_to :scale_type
  belongs_to :transport_type
  belongs_to :region
  has_many :log_parts
  has_many :food_types, :through => :log_parts

  accepts_nested_attributes_for :log_volunteers

  validates :notes, presence: { if: Proc.new{ |a| a.complete and a.summed_weight == 0 and a.summed_count == 0 }, 
            message: "can't be blank if weights/counts are all zero: let us know what happened!" }
  validates :transport_type_id, presence: { if: :complete }
  validates :donor_id, presence: { if: :complete }
  validates :recipient_id, presence: { if: :complete }
  validates :volunteer_id, presence: { if: :complete }
  validates :when, presence: true

  attr_accessible :schedule_id, :region_id, :volunteer_id, :donor_id, :recipient_id, 
                  :food_type_id, :transport_type_id, :flag_for_admin, :notes, 
                  :num_reminders, :orig_volunteer_id, :transport, :when, :scale_type_id, :log_volunteers_attributes

  after_save { |record| tweet(record) }

  before_save { |record|
    record.scale_type = record.region.scale_types.first if record.scale_type.nil?
    if record.scale_type.changed?
      weight_unit = record.scale_type.weight_unit
      record.log_parts.each{ |lp|
        lp.weight = (lp.weight * (1/2.2).to_f) if weight_unit == "kg"
        lp.weight = (conv_weight * (1/14).to_f) if weight_unit == "st"
      }
    end
  }

  TweetGainThreshold = 25000
  TweetTimeThreshold = 3600*24
  TweetGainOrTime = :gain

  def has_volunteers?
    self.volunteers.count > 0
  end

  def no_volunteers?
    self.volunteers.count == 0
  end

  def has_volunteer? volunteer
    return false if volunteer.nil?
    self.volunteers.collect { |v| v.id }.include? volunteer.id
  end

  def self.pickup_count region_id
    self.where(:region_id=>region_id, :complete=>true).count
  end

  def self.picked_up_by(volunteer_id,complete=true,limit=nil)
    if limit.nil?
      self.joins(:log_volunteers).where("log_volunteers.volunteer_id = ? AND logs.complete=? AND log_volunteers.active",volunteer_id,complete).order('"logs"."when" DESC')
    else
      self.joins(:log_volunteers).where("log_volunteers.volunteer_id = ? AND logs.complete=? AND log_volunteers.active",volunteer_id,complete).order('"logs"."when" DESC').limit(limit.to_i)
    end
  end

  def self.picked_up_weight(volunteer_id)
    complete = true
    self.joins(:log_volunteers,:log_parts).where("log_volunteers.volunteer_id = ? AND logs.complete=? AND log_volunteers.active",volunteer_id,complete).sum(:weight)
  end

  def self.upcoming_for(volunteer_id)
    self.joins(:log_volunteers).where("log_volunteers.volunteer_id = ? AND log_volunteers.active",volunteer_id).
      where("\"when\" >= ?",Time.zone.today)
  end

  def self.past_for(volunteer_id)
    self.joins(:log_volunteers).where("log_volunteers.volunteer_id = ? AND log_volunteers.active",volunteer_id).
      where("\"when\" < ?",Time.zone.today)
  end

  def self.needing_coverage region_id_list=nil
    unless region_id_list.nil?
      return self.joins("LEFT OUTER JOIN log_volunteers ON log_volunteers.log_id=logs.id").where("volunteer_id IS NULL").where(:region_id=>region_id_list).where("\"when\" >= ?",Time.zone.today)
    else
      return self.joins("LEFT OUTER JOIN log_volunteers ON log_volunteers.log_id=logs.id").where("volunteer_id IS NULL").where("\"when\" >= ?",Time.zone.today)
    end
  end

  def self.being_covered region_id_list=nil
    unless region_id_list.nil?
      return self.select("logs.*, count(log_volunteers.volunteer_id) as prior_count").joins(:log_volunteers).
        where("NOT log_volunteers.active").
        where(:region_id=>region_id_list).
        where("\"when\" >= ?",Time.zone.today).
        group("logs.id")
    else
      return self.select("logs.*, count(log_volunteers.volunteer_id) as prior_count").joins(:log_volunteers).
        where("NOT log_volunteers.active").
        where("\"when\" >= ?",Time.zone.today).group("logs.id")
    end
  end


  def summed_weight
    self.log_parts.collect{ |lp| lp.weight }.compact.sum
  end

  def summed_count
    self.log_parts.collect{ |lp| lp.count }.compact.sum
  end

  def prior_volunteers
    self.log_volunteers.collect{ |sv| (not sv.active) ? sv.volunteer : nil }.compact
  end

  def tweet(record)
    return true if record.region.nil? or record.region.twitter_key.nil? or record.region.twitter_secret.nil? or record.region.twitter_token.nil? or 
                   record.region.twitter_token_secret.nil?
    return true unless record.complete

    poundage = Log.where("complete AND region_id = ?",region.id).collect{ |l| l.summed_weight }.sum
    poundage += record.region.prior_lbs_rescued unless record.region.prior_lbs_rescued.nil?
    last_poundage = region.twitter_last_poundage.nil? ? 0.0 : region.twitter_last_poundage

    if TweetGainOrTime == :time
      return true unless record.region.twitter_last_timestamp.nil? or (Time.zone.now - record.region.twitter_last_timestamp) > TweetTimeThreshold
      # flip a coin about whether we'll post this one so we don't always post at the same time of day
      return true if rand > 0.5
    else
      return true unless (poundage - last_poundage >= TweetGainThreshold)
    end

    begin
      Twitter.configure do |config|
        config.consumer_key = record.region.twitter_key
        config.consumer_secret = record.region.twitter_secret
        config.oauth_token = record.region.twitter_token
        config.oauth_token_secret = record.region.twitter_token_secret
      end
      if poundage <= last_poundage
        region.twitter_last_poundage = poundage
        region.save
        return true
      end
      t = "#{record.volunteer.name} picked up #{record.summed_weight.round} lbs of food, bringing 
           us to #{poundage.round} lbs of food rescued to date in #{record.region.name}."
      if record.donor.twitter_handle.nil?
        t += "Thanks to #{record.donor.name} for the donation!"
      else
        t += " Thanks to @#{record.donor.twitter_handle} for the donation!"
      end
      return true if t.length > 140
      Twitter.update(t)
      record.region.twitter_last_poundage = poundage
      record.region.twitter_last_timestamp = Time.zone.now
      record.region.save
      flash[:notice] = "Tweeted: #{t}"
    rescue
      # Twitter update didn't work for some reason, but everything else seems to have...
    end
    return true
  end

end
