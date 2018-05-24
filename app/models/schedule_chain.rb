# frozen_string_literal: true

class ScheduleChain < ActiveRecord::Base
  default_scope { where(active: true) }

  belongs_to :transport_type
  belongs_to :scale_type
  belongs_to :region

  has_many :schedule_volunteers
  has_many :volunteers, through: :schedule_volunteers,
                        conditions: { 'schedule_volunteers.active' => true }

  has_many :schedules
  has_many :locations, through: :schedules

  has_many :logs

  attr_accessible :region_id, :irregular, :backup, :transport_type_id,
                  :day_of_week, :detailed_start_time, :detailed_stop_time,
                  :detailed_date, :frequency, :temporary, :difficulty_rating,
                  :expected_weight, :hilliness, :schedule_volunteers,
                  :schedule_volunteers_attributes, :scale_type_ids,
                  :schedule_ids, :admin_notes, :public_notes, :schedules,
                  :schedule, :schedule_volunteers, :schedules_attributes,
                  :num_volunteers, :active

  accepts_nested_attributes_for :schedule_volunteers
  accepts_nested_attributes_for :schedules

  HILLINESS_OPTIONS = [
    'Flat',
    'Mostly Flat',
    'Some Small Hills',
    'Hilly for Reals',
    'Mountaineering'
  ].freeze

  DIFFICULTY_OPTIONS = [
    'Easiest',
    'Typical',
    'Challenging',
    'Most Difficult'
  ].freeze

  after_save do |record|
    record.schedule_volunteers.each do |sv|
      sv.destroy if sv.volunteer_id.blank?
    end
  end

  def covered?
    volunteers.count >= num_volunteers
  end

  # does the schedule chain start with a pickup and end with a dropoff?
  def functional?
    !schedules.empty? &&
      schedules.first.pickup_stop? &&
      schedules.last.drop_stop?
  end

  def mappable?
    functional? && schedules.all? do |s|
      s.location.present? && s.location.address.present?
    end
  end

  # list all the schedules that don't have enough active volunteers
  # clarification: (in my regions) and (temporary or (no volunteers and last stop is dropoff))
  def self.open_in_regions(region_id_list)
    schedules = ScheduleChain.where(irregular: false).where(region_id: region_id_list) unless region_id_list.empty?
    return [] if schedules.nil?
    schedules.keep_if do |schedule|
      if schedule.functional?
        schedule.temporary || !schedule.covered?
      else
        false
      end
    end
    schedules
  end

  def self.for_location(loc)
    if loc.donor?
      ScheduleChain.for_donor(loc)
    else
      ScheduleChain.for_recipient(loc)
    end
  end

  def self.for_donor(d)
    Schedule.joins(:location).where('locations.location_type = ? AND locations.id = ?', Location::LOCATION_TYPES.invert['Donor'], d.id).collect(&:schedule_chain).uniq
  end

  def self.for_recipient(r)
    Schedule.joins(:location).where('NOT locations.location_type = ? AND locations.id = ?', Location::LOCATION_TYPES.invert['Recipient'], r.id).collect(&:schedule_chain).uniq
  end

  def food_types
    schedules.collect(&:food_types).flatten.uniq
  end

  def volunteers?
    volunteers.count.positive?
  end

  def no_volunteers?
    volunteers.count.zero?
  end

  def volunteers_needing_training?
    somebody_needs_training = false
    volunteers.each { |volunteer| somebody_needs_training |= volunteer.needs_training? }
    somebody_needs_training
  end

  def prior_volunteers
    schedule_volunteers.collect { |sv| !sv.active ? sv.volunteer : nil }.compact
  end

  def volunteer?(volunteer)
    return false if volunteer.nil?
    volunteers.collect(&:id).include?(volunteer.id)
  end

  def one_time?
    frequency == 'one-time'
  end

  def weekly?
    frequency == 'weekly'
  end

  def max_weight
    logs.collect(&:summed_weight).compact.max
  end

  def mean_weight
    ls = logs.collect(&:summed_weight)
    ls.empty? ? nil : ls.sum / ls.length
  end

  def next_pickup_time
    return nil unless weekly? && !irregular

    next_pickup = Time.zone.today
    next_pickup += 1 if day_of_week == next_pickup.wday &&
                        detailed_start_time.strftime('%H%m').to_i < Time.zone.now.strftime('%H%m').to_i

    while next_pickup.wday != day_of_week
      next_pickup += 1
    end

    {
      start: Time.new(
        next_pickup.year,
        next_pickup.month,
        next_pickup.day,
        detailed_start_time.hour,
        detailed_start_time.min
      ),
      stop: Time.new(
        next_pickup.year,
        next_pickup.month,
        next_pickup.day,
        detailed_stop_time.hour,
        detailed_stop_time.min
      )
    }
  end

  def donor_stops
    schedules.select(&:pickup_stop?)
  end

  def recipient_stops
    schedules.select(&:drop_stop?)
  end

  def donors
    donor_stops.collect(&:location)
  end

  def recipients
    recipient_stops.collect(&:location)
  end

  def from_to_name
    "#{schedules.first.location.try(:name)} to #{schedules.last.location.try(:name)}"
  end

  def related_shifts
    location_ids = donors.collect { |donor|
      donor.location_type == Location::LOCATION_TYPES.invert['Hub'] ? nil : donor.id
    }.compact

    return [] if location_ids.empty?

    Schedule.where('schedule_chain_id != ?', id).where(location_id: location_ids).reject do |x|
      x.schedule_chain.nil?
    end
  end
end
