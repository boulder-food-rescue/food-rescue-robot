# frozen_string_literal: true

class CreateTransportTypes < ActiveRecord::Migration
  def change
    create_table :transport_types do |t|
      t.string :name

      t.timestamps
    end
  end
end
