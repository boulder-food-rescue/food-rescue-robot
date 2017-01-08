class Shift
  attr_reader :logs

  delegate :when,
           :region,
           :absences,
           :schedule_chain,
           to: :first_log

  def self.build_shifts(logs)
    shifts = []
    group = {}
    logs.each { |log|
      if log.schedule_chain.nil?
        shifts << [log]
      else
        key = [log.when, log.schedule_chain_id].join(":")
        if group[key].nil?
          group[key] = shifts.length
          shifts << []
        end
        shifts[group[key]] << log
      end
    }

    shifts.map { |shift_logs| new(shift_logs) }
  end

  def initialize(logs)
    @logs = logs
  end

  def first_log
    logs.first
  end
end
