# frozen_string_literal: true

class Shift
  attr_reader :logs

  delegate :when,
           :region,
           :absences,
           :schedule_chain,
           to: :first_log

  def self.build_shifts_eagerly(log_ids)
    logs = Log.includes(:schedule_chain).find(log_ids)
    Shift.build_shifts(logs)
  end

  def self.build_shifts(logs)
    shifts = []
    group = {}
    logs.each do |log|
      if log.schedule_chain.nil?
        shifts << [log]
      else
        key = [log.when, log.schedule_chain_id].join(':')
        if group[key].nil?
          group[key] = shifts.length
          shifts << []
        end
        shifts[group[key]] << log
      end
    end

    shifts.map { |shift_logs| new(shift_logs) }
  end

  def initialize(logs)
    @logs = logs
  end

  def first_log
    logs.first
  end

  def log_ids
    logs.map(&:id)
  end

  def volunteers
    logs.flat_map(&:volunteers).uniq
  end

  def transport_types
    logs.map(&:transport_type).compact
  end

  def food_types_by_log
    logs.map(&:food_types)
  end

  def donors
    logs.map(&:donor).compact
  end

  def recipients
    logs.flat_map(&:recipients).uniq
  end

  def summed_weight
    logs.sum(&:summed_weight)
  end

  def complete?
    logs.all?(&:complete)
  end

  def volunteers_need_training?
    volunteers.any?(&:needs_training?)
  end

  def volunteers_needed?
    logs.any? { |log| log.volunteers.empty? }
  end
end
