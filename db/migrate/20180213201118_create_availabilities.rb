class CreateAvailabilities < ActiveRecord::Migration
  def change
    create_table :availabilities do |t|
      t.references :volunteer
      t.integer :day
      t.integer :time

      t.timestamps
    end
    add_index :availabilities, :volunteer_id
  end
end
