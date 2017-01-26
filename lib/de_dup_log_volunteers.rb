class DeDupLogVolunteers
  def self.de_duplicate
    too_many_records = LogVolunteer.select([:id, :log_id, :volunteer_id]).all
    # that is a "make it work" solution. if it takes too long,
    # do the work to run a SQL query
    dups = too_many_records.group_by { |r| [r.log_id, r.volunteer_id] }
    dups.each do |group, records|
      records[1..-1].each(&:destroy)
    end
  end
end
