# frozen_string_literal: true

class AddWelcomeEmailTextToRegions < ActiveRecord::Migration
  def change
    change_table :regions do |t|
      t.text :welcome_email_text
    end
  end
end
