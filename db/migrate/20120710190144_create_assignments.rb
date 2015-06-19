class CreateAssignments < ActiveRecord::Migration
  def change
    create_table :assignments do |t|
      t.references :volunteer
      t.references :region
      t.boolean :admin

      t.timestamps
    end
    add_index :assignments, :volunteer_id
    add_index :assignments, :region_id
  end
end
