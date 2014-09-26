class AddAuthTokenToVolunteers < ActiveRecord::Migration
  def change
    add_column :volunteers, :authentication_token, :string
  end
end
