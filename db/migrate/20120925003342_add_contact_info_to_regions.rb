# frozen_string_literal: true

class AddContactInfoToRegions < ActiveRecord::Migration
  def change
    change_table :regions do |t|
      t.string :phone
      t.string :tax_id
    end
    change_table :locations do |t|
      t.string :receipt_key
    end
  end
end
