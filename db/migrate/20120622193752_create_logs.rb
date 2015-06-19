class CreateLogs < ActiveRecord::Migration
  def change
    create_table :logs do |t|
      t.references :schedule
      t.date :when
      t.references :volunteer
      t.integer :orig_volunteer_id
      t.decimal :weight
      t.text :description
      t.string :transport
      t.text :notes
      t.integer :num_reminders
      t.boolean :flag_for_admin
      t.string :weighed_by

      t.timestamps
    end
    add_index :logs, :schedule_id
    add_index :logs, :volunteer_id
  end
end
