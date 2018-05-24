# frozen_string_literal: true

class VolunteersAddSncsBoolean < ActiveRecord::Migration
  def up
    add_column :volunteers, :get_sncs_email, :boolean, :null => false, :default => false
  end

  def down
    remove_column :volunteers, :get_sncs_email
  end
end
