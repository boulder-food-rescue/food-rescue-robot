# frozen_string_literal: true

class AddWhyZeroToLog < ActiveRecord::Migration
  def change
    add_column :logs, :why_zero, :integer
  end
end
