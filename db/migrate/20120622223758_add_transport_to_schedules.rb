class AddTransportToSchedules < ActiveRecord::Migration
  def change
    add_column :schedules, :transport, :string
  end
end
