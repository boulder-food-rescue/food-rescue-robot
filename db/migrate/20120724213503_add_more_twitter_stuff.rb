class AddMoreTwitterStuff < ActiveRecord::Migration
  def change
    change_table :regions do |t|
      t.integer :twitter_last_poundage
      t.datetime :twitter_last_timestamp
    end
  end
end
