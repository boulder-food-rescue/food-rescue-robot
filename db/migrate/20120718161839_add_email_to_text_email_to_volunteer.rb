# frozen_string_literal: true

class AddEmailToTextEmailToVolunteer < ActiveRecord::Migration
  def up
    create_table :cell_carriers do |t|
      t.string :name
      t.string :format
    end

    # These are taken from: http://www.emailtextmessages.com/
    CellCarrier.create :name => 'T-Mobile', :format => '%d@tmomail.net'
    CellCarrier.create :name => 'AT&T', :format => '%d@txt.att.net'
    CellCarrier.create :name => 'Verizon', :format => '%d@vtext.com'
    CellCarrier.create :name => 'Boost Mobile', :format => '%d@myboostmobile.com'
    CellCarrier.create :name => 'Nextel', :format => '%d@messaging.nextel.com'
    CellCarrier.create :name => 'Sprint', :format => '%d@messaging.sprintpcs.com'

    change_table :volunteers do |t|
      t.references :cell_carrier
      t.boolean :sms_too, :default => false
    end
  end

  def down
    remove_column :volunteers, :cell_carrier_id
    remove_column :volunteers, :sms_too
    drop_table :cell_carriers
  end
end
