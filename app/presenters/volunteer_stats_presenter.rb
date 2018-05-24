# frozen_string_literal: true

class VolunteerStatsPresenter
  def initialize(volunteer, time = Time.zone.now)
    @volunteer = volunteer
    @time = time
  end

  def first_pickup_date
    return nil if logs.empty?
    logs.last.when
  end

  def pickup_stats
    @pickup_stats ||= PickupStatsPresenter.new(
      first_pickup_date,
      logs,
      time
    )
  end

  def lbs_by_month_graph
    @lbs_by_month_graph ||= LbsByMonthGraphPresenter.new(
      (first_pickup_date || today.beginning_of_month)..today,
      logs
    )
  end

  private

  attr_reader :volunteer,
              :time

  def logs
    @logs ||= Log.picked_up_by(volunteer.id).
      where('"logs"."when" < ?', time).
      includes(:log_parts)
  end

  def today
    time.to_date
  end
end
