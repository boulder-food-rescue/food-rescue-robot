# frozen_string_literal: true

class AddIrregularToSchedule < ActiveRecord::Migration
  def change
    add_column :schedules, :irregular, :boolean
    add_column :schedules, :backup, :boolean
  end
end
