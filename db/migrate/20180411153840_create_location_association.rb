class CreateLocationAssociation < ActiveRecord::Migration
  def up
    create_table :location_associations do |t|
      t.references :location_admin
      t.references :location
      t.timestamps
    end
    add_index :location_associations, :location_admin_id
    add_index :location_associations, :location_id
  end

  def down
    drop_table :location_associations
  end
end
