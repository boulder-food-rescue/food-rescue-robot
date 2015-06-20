class CreateAbsences < ActiveRecord::Migration
  def up
    create_table :absences do |t|
      t.belongs_to :volunteer
      t.date :start_date
      t.date :stop_date
      t.text :comments
    end
    create_table :absences_logs do |t|
      t.belongs_to :absence
      t.belongs_to :log
    end
    change_table :log_volunteers do |t|
      t.boolean :covering
    end
  end

  def down
    drop_table :absences
    drop_table :absences_logs
    remove_column :log_volunteers, :covering
  end
end
