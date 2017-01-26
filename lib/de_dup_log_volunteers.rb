class DeDupLogVolunteers
  def self.de_duplicate
    dup_pairs = LogVolunteer.select(
      ['count(1) as ct', :log_id, :volunteer_id]
    ).having('1 < ct').group(:log_id, :volunteer_id)
    dup_pairs.each do |dp|
      dups = LogVolunteer.where(log_id: dp.log_id, volunteer_id: dp.volunteer_id)
      covering = dups.inject(false) { |covering, d| covering || d.covering }
      active = dups.inject(false) { |active, d| active || d.active }
      dups[1..-1].each(&:destroy)
      dups[0].covering = covering
      dups[0].active = active
      dups[0].save!
    end
  end
end
