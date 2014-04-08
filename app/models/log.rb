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
  validates :scale_type_id, presence: { if: :complete }
  validates :when, presence: true

  attr_accessible :schedule_id, :region_id, :donor_id, :recipient_id,
                  :food_type_id, :transport_type_id, :flag_for_admin, :notes, 
                  :num_reminders, :transport, :when, :scale_type_id,
                  :log_volunteers_attributes, :weight_unit

  after_save { |record| record.tweet }

  before_save { |record|
    record.scale_type = record.region.scale_types.first if record.scale_type.nil? and record.region.scale_types.length == 1
    unless record.scale_type.nil?
      record.weight_unit = record.scale_type.weight_unit if record.weight_unit.nil?
      record.log_parts.each{ |lp|
        if record.weight_unit == "kg"
          lp.weight = (lp.weight * (1.0/2.2).to_f).round(2)
        elsif record.weight_unit == "st"
          lp.weight = (conv_weight * (1.0/14.0).to_f).round(2)
        end
        lp.save
      }
      record.weight_unit = "lb"
    end
  }

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

  def self.picked_up_weight(region_id=nil,volunteer_id=nil)
    cq = "logs.complete"
    vq = volunteer_id.nil? ? nil : "log_volunteers.volunteer_id=#{volunteer_id}"
    rq = region_id.nil? ? nil : "logs.region_id=#{region_id}"
    aq = "log_volunteers.active"
    self.joins(:log_volunteers,:log_parts).where([cq,vq,rq,aq].compact.join(" AND ")).sum(:weight).to_f
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

  TweetGainThreshold = 25000
  TweetTimeThreshold = 3600*24
  TweetGainOrTime = :gain

  def tweet
    return true if self.region.nil? or self.region.twitter_key.nil? or self.region.twitter_secret.nil? or self.region.twitter_token.nil? or 
                   self.region.twitter_token_secret.nil?
    return true unless self.complete

    poundage = Log.picked_up_weight(region.id)
    poundage += self.region.prior_lbs_rescued unless self.region.prior_lbs_rescued.nil?
    last_poundage = region.twitter_last_poundage.nil? ? 0.0 : region.twitter_last_poundage

    if TweetGainOrTime == :time
      return true unless self.region.twitter_last_timestamp.nil? or (Time.zone.now - self.region.twitter_last_timestamp) > TweetTimeThreshold
      # flip a coin about whether we'll post this one so we don't always post at the same time of day
      return true if rand > 0.5
    else
      return true unless (poundage - last_poundage >= TweetGainThreshold)
    end

    begin
      Twitter.configure do |config|
        config.consumer_key = self.region.twitter_key
        config.consumer_secret = self.region.twitter_secret
        config.oauth_token = self.region.twitter_token
        config.oauth_token_secret = self.region.twitter_token_secret
      end
      if poundage <= last_poundage
        region.twitter_last_poundage = poundage
        region.save
        return true
      end
      t = "#{self.volunteers.collect{ |v| v.name }.join(" and ")} picked up #{self.summed_weight.round} lbs of food, bringing
           us to #{poundage.round} lbs of food rescued to date in #{self.region.name}."
      if self.donor.twitter_handle.nil?
        t += "Thanks to #{self.donor.name} for the donation!"
      else
        t += " Thanks to @#{self.donor.twitter_handle} for the donation!"
      end
      return true if t.length > 140
      Twitter.update(t)
      self.region.twitter_last_poundage = poundage
      self.region.twitter_last_timestamp = Time.zone.now
      self.region.save
      flash[:notice] = "Tweeted: #{t}"
    rescue
      # Twitter update didn't work for some reason, but everything else seems to have...
    end
    return true
  end

end
