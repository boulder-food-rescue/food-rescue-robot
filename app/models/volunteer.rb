class Volunteer < ActiveRecord::Base
  attr_accessible :admin_notes, :email, :gone_until, :has_car, :is_disabled, :name, :on_email_list, :phone, :pickup_prefs, :preferred_contact, :transport
end
