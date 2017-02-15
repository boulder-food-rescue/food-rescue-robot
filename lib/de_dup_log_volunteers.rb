class DeDupLogVolunteers
  def self.de_duplicate
    ActiveRecord::Base.connection.execute <<-SQL
WITH t AS (
  SELECT
    id,
    volunteer_id,
    log_id,
    rank() OVER (
      PARTITION BY volunteer_id, log_id ORDER BY created_at DESC
    ) AS rank
  FROM log_volunteers
  WHERE active = true
)
UPDATE log_volunteers
SET active = false
WHERE id IN (SELECT id FROM t WHERE rank > 1);
    SQL
  end
end
