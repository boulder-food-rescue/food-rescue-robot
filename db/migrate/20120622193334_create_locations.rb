# frozen_string_literal: true

class CreateLocations < ActiveRecord::Migration
  def change
    create_table :locations do |t|
      t.boolean :is_donor
      t.string :recip_category
      t.string :donor_type
      t.text :address
      t.string :name
      t.decimal :lat
      t.decimal :lng
      t.text :contact
      t.string :website
      t.text :admin_notes
      t.text :public_notes
      t.text :hours

      t.timestamps
    end
  end
end
