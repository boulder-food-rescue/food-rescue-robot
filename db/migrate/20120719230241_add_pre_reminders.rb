# frozen_string_literal: true

class AddPreReminders < ActiveRecord::Migration
  def up
    change_table :volunteers do |t|
      t.boolean :pre_reminders_too, :default => false
    end
  end
end
