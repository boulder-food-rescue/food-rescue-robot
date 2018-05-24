# frozen_string_literal: true

class RemoveTimeStartAndTimeStop < ActiveRecord::Migration
  def up
    remove_column :schedules, :time_start
    remove_column :schedules, :time_stop
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
