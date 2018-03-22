# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ :name => 'Chicago' }, { :name => 'Copenhagen' }])
#   Mayor.create(:name => 'Emanuel', :city => cities.first)

# Create global transport types
[
  {name: 'Bike'},
  {name: 'Car'},
  {name: 'Foot'}
].each do |attrs|
  TransportType.create(attrs)
end

# Create global cell phone carriers
[
  { name: 'T-Mobile', format: '%d@tmomail.net' },
  { name: 'AT&T', format: '%d@txt.att.net' },
  { name: 'Verizon', format: '%d@vtext.com' },
  { name: 'Boost Mobile', format: '%d@myboostmobile.com' },
  { name: 'Nextel', format: '%d@messaging.nextel.com' },
  { name: 'Sprint', format: '%d@messaging.sprintpcs.com' }
].each do |attrs|
  CellCarrier.create(attrs)
end

#region.attributes.slice('lat', 'lng', 'name', 'website', 'address', 'notes', 'handbook_url', 'prior_lbs_rescued', 'prior_num_pickups', 'title', 'tagline', 'phone', 'tax_id', 'welcome_email_text', 'splash_html', 'weight_unit', 'time_zone', 'volunteer_coordinator_email', 'post_pickup_emails', 'unschedule_self' )
region = Region.create({
  'lat'=> 41.5409097,
  'lng'=> -72.9990631,
  'name'=>'Boulder Food Rescue',
  'website'=>'',
  'address'=>'Hana Danksy',
  'notes'=>'',
  'handbook_url'=>'',
  'title'=>'Boulder Food Rescue',
  'tagline'=>'',
  'phone'=>'208-123-5354',
  'tax_id'=>'',
  'welcome_email_text'=>'',
  'splash_html'=>'',
  'weight_unit'=>'pound',
  'time_zone'=>'',
  'volunteer_coordinator_email'=>'volunteer@gmail.com',
  'post_pickup_emails'=>false,
  'unschedule_self'=>false
})

#volunteer.attributes.slice('email', 'name', 'phone', 'preferred_contact', 'has_car', 'admin_notes', 'pickup_prefs', 'is_disabled', 'on_email_list', 'admin', 'transport_type_id', 'cell_carrier_id', 'sms_too', 'pre_reminders_too', 'get_sncs_email', 'waiver_signed', 'waiver_signed_at', 'assigned', 'requested_region_id', 'active')
#assignment.attributes.slice('volunteer_id', 'region_id', 'admin')

volunteer = Volunteer.create({
  'email'=>'volunteer.bfr@gmail.com',
   'name'=>'Volunteer',
   'phone'=>'760-815-5555',
   'password' => 'changeme!',
   'password_confirmation' => 'changeme!',
   'preferred_contact'=>'Text',
   'has_car'=>true,
   'is_disabled'=>false,
   'on_email_list'=>true,
   'transport_type_id'=>1,
   'cell_carrier_id'=>6,
   'sms_too'=>false,
   'pre_reminders_too'=>false,
   'get_sncs_email'=>true,
   'assigned'=>true
})

volunteer.waiver_signed = true
volunteer.waiver_signed_at = DateTime.now
volunteer.active = true
volunteer.save!

# Create volunteer assignment
assignment = Assignment.new({admin: false})

assignment.volunteer_id = volunteer.id
assignment.region_id = region.id
assignment.save!

super_admin = Volunteer.create({
  'email'=>'superadmin.bfr@gmail.com',
   'name'=>'Super Admin',
   'password' => 'changeme!',
   'password_confirmation' => 'changeme!',
   'phone'=>'760-888-5555',
   'preferred_contact'=>'Text',
   'has_car'=>true,
   'is_disabled'=>false,
   'on_email_list'=>true,
   'transport_type_id'=>1,
   'cell_carrier_id'=>6,
   'sms_too'=>false,
   'pre_reminders_too'=>false,
   'get_sncs_email'=>true,
   'assigned'=>true
})

super_admin.admin = true
super_admin.waiver_signed = true
super_admin.waiver_signed_at = DateTime.now
super_admin.active = true
super_admin.save


region_admin = Volunteer.create({
  'email'=>'regionadmin.bfr@gmail.com',
   'name'=>"Region Admin #{region.name}",
   'phone'=>'760-888-5555',
   'password' => 'changeme!',
   'password_confirmation' => 'changeme!',
   'preferred_contact'=>'Text',
   'has_car'=>true,
   'is_disabled'=>false,
   'on_email_list'=>true,
   'transport_type_id'=>1,
   'cell_carrier_id'=>6,
   'sms_too'=>false,
   'pre_reminders_too'=>false,
   'get_sncs_email'=>true,
   'assigned'=>true
})

region_admin.admin = false
region_admin.waiver_signed = true
region_admin.waiver_signed_at = DateTime.now
region_admin.active = true
region_admin.save

# Create region admin assignment
admin_assignment = Assignment.new({admin: true})

admin_assignment.volunteer_id = region_admin.id
admin_assignment.region_id = region.id
admin_assignment.save!


#Create donor location
donor = Location.create({
     'location_type' => 1,
     'name' => "Test Donor",
     'active' => true,
     'region_id' => region.id,
     'address' => "123 Side St."
})
#Create recipient location

recipient = Location.create({
     'location_type' => 0,
     'name' => "Test Recipient",
     'active' => true,
     'region_id' => region.id,
     'address' => "123 Main St."

})

#Create schedule chain

schedule_chain = ScheduleChain.create({
     'detailed_start_time' => "2000-01-01 08:00:00",
     'detailed_stop_time' => "2000-01-01 11:00:00",
     'detailed_date' => "2018-02-28",
     'transport_type_id' => 2,
     'region_id'=> region.id,
     'frequency'=> 'weekly',
     'day_of_week'=> 1
})

#Assign donor location to schedule
Schedule.create({
    'schedule_chain_id' => schedule_chain.id,
    'location_id' => donor.id,
    'position' => 1
})

#Assign recipient location to schedule
Schedule.create({
    'schedule_chain_id' => schedule_chain.id,
    'location_id' => recipient.id,
    'position' => 2
})

#Assign schedule to volunteer

ScheduleVolunteer.create({
    'volunteer_id' => volunteer.id,
    'schedule_chain_id' => schedule_chain.id,
    'active' => true
})


#Generate log of the schedule, instructions found in log_builder.rb

chain = FoodRobot::LogGenerator::ScheduleChainDecorator.new(schedule_chain)
donor_chain = chain.donors.first
date = Date.today - 7
FoodRobot::LogGenerator::LogBuilder.new(date, donor_chain, nil).log.save #Log for past pick up

date = Date.today + 100
FoodRobot::LogGenerator::LogBuilder.new(date, donor_chain, nil).log.save #Log for future pick up
