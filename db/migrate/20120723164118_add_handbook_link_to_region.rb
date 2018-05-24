# frozen_string_literal: true

class AddHandbookLinkToRegion < ActiveRecord::Migration
  def change
    change_table :regions do |t|
      t.string :handbook_url
    end
  end
end
