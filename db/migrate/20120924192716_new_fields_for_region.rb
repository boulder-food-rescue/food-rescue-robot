class NewFieldsForRegion < ActiveRecord::Migration
  def up
    change_table :regions do |t|
      t.string :title
      t.string :tagline
    end
    add_attachment :regions, :logo
  end
  def down
    remove_column :regions, :title
    remove_column :regions, :tagline
    remove_attachment :regions, :logo
  end
end
