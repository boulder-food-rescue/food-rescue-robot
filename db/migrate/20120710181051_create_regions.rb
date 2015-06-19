class CreateRegions < ActiveRecord::Migration
  def change
    create_table :regions do |t|
      t.decimal :lat
      t.decimal :lng
      t.string :name
      t.string :website
      t.text :address
      t.text :notes

      t.timestamps
    end
  end
end
