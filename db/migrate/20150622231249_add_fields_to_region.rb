# frozen_string_literal: true

class AddFieldsToRegion < ActiveRecord::Migration
  def change
    add_column :regions, :volunteer_coordinator_email, :string
    add_column :regions, :post_pickup_emails, :boolean, :default => false
    add_column :regions, :unschedule_self, :boolean, :default => false
  end
end
