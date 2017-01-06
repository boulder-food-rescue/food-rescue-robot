class VolunteerStatsPresenter
  class LbsByMonthGraphPresenter
    def initialize(date_range, logs)
      @date_range = date_range
      @logs = logs
    end

    def labels
      active_months.map { |m| m.strftime('%Y-%m') }
    end

    def values
      active_months.map do |m|
        if logs_by_month[m].present?
          logs_by_month[m].sum(&:summed_weight)
        else
          0
        end
      end
    end

    private

    attr_reader :date_range,
                :logs

    def active_months
      @active_months ||= date_range.map { |d| d.beginning_of_month }.uniq
    end

    def logs_by_month
      @logs_by_month ||= logs.group_by { |l| l.when.beginning_of_month }
    end
  end
end
