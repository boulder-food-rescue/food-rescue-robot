class CreateScaleTypes < ActiveRecord::Migration
  def change
    create_table :scale_types do |t|
      t.string :name
      t.string :weight_unit
      t.timestamps
    end
  end
  def up
  end

  def down
  end
end
