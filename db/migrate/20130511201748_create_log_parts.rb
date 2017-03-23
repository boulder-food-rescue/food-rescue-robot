class CreateLogParts < ActiveRecord::Migration
  def up
    create_table :log_parts do |t|
      t.references :log
      t.references :food_type
      t.boolean :required
      t.decimal :weight

      t.timestamps
    end
    add_index :log_parts, :log_id
    add_index :log_parts, :food_type_id

    change_table :logs do |t|
      t.boolean :complete, :default => 'f'
    end
    execute "UPDATE logs SET complete='t' WHERE weight IS NOT NULL;"

    ft_merge = {}
    Log.all.each{ |l|
      lp = LogPart.new
      lp.log_id = l.id
      lp.weight = l.weight
      lp.food_type_id = l.food_type_id
      lp.required = true
      lp.save
    }
    remove_column :logs, :weight
    remove_column :logs, :food_type_id
  end

  def down
    change_table :logs do |t|
      t.decimal :weight
      t.references :food_type
    end
    drop_table :log_parts
    remove_column :logs, :complete
  end
end
