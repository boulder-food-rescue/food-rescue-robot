class AddEmailAndPhoneToLocation < ActiveRecord::Migration
  def change
    change_table :locations do |t|
      t.text :email
      t.text :phone
    end
  end
end
