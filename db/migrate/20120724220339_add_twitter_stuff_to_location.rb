class AddTwitterStuffToLocation < ActiveRecord::Migration
  def change
    change_table :locations do |t|
      t.string :twitter_handle
    end
  end
end
