class VolunteersAddSncsBoolean < ActiveRecord::Migration
  def up
    add_column :volunteers, :get_sncs_email, :boolean, :null => false, :default => 'f'
  end

  def down
    remove_column :volunteers, :get_sncs_email
  end
end
