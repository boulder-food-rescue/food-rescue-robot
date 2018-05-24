# frozen_string_literal: true

class AddSplashHtmlToRegion < ActiveRecord::Migration
  def change
    change_table :regions do |t|
      t.text :splash_html
    end
  end
end
