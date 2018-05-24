# frozen_string_literal: true

class CreateSchedules < ActiveRecord::Migration
  def change
    create_table :schedules do |t|
      t.integer :recipient_id
      t.integer :donor_id
      t.references :volunteer
      t.integer :prior_volunteer_id
      t.integer :day_of_week
      t.integer :time_start
      t.integer :time_stop
      t.text :admin_notes
      t.text :public_notes
      t.boolean :needs_training

      t.timestamps
    end
    add_index :schedules, :volunteer_id
  end
end
