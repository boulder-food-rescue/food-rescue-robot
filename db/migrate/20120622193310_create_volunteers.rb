# frozen_string_literal: true

class CreateVolunteers < ActiveRecord::Migration
  def change
    create_table :volunteers do |t|
      t.string :email
      t.string :name
      t.string :phone
      t.string :preferred_contact
      t.string :transport
      t.boolean :has_car
      t.text :admin_notes
      t.text :pickup_prefs
      t.date :gone_until
      t.boolean :is_disabled
      t.boolean :on_email_list

      t.timestamps
    end
  end
end
