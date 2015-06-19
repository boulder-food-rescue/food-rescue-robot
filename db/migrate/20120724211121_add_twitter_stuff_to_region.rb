class AddTwitterStuffToRegion < ActiveRecord::Migration
  def change
    change_table :regions do |t|
      t.string :twitter_key
      t.string :twitter_secret
      t.string :twitter_token
      t.string :twitter_token_secret
    end
  end
end
