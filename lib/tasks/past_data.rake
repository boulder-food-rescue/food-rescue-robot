require 'csv'
require 'json'

namespace :past_data do
  task :import => [:environment, :import_volunteers, :import_locations, :import_farmers_market_data]  do
    csv_text = File.read('./lib/tasks/data/TC Food Justice Rescue Log (Responses) For Real - Form Responses 1.csv')
    completed_file = File.read('./lib/tasks/data/completed.json')
    csv = CSV.parse(csv_text, :headers => true)
    skipped = {} #keeps track of which rows were skipped due to missing info in the DB
    completed = JSON.parse(completed_file) #keeps track of which rows were successfully added to the db
    index = 1
    farmers_market = ["NE Farmer's Market", "Nokomis Farmer's Market"]
    food = FoodType.where('name':'Food')[0]
    scale = ScaleType.find(1)
    if food.blank? || scale.blank?
      puts "ERROR! MISSING FOOD TYPES OR SCALE IN DATABASE"
      return
    end
    csv.each do |row|
      index += 1
      next if completed.key?(index.to_s)
      next if farmers_market.include?(row['3. Where are you picking up from?'])
      volunteers = get_volunteers(row['2. Names of Volunteers (first, last)'])
      if volunteers.nil?
        skipped[index] = "missing volunteer"
        next
      end
      donor = Location.where('name': row['3. Where are you picking up from?'])[0]
      if donor.nil?
        skipped[index] = "missing donor"
        next
      end
      recipient = Location.where('name': row['5. What is the drop off location?'])[0]
      if recipient.nil?
        skipped[index] = "missing recipient"
        next
      end
      transportation = TransportType.where('name': row['6. How did you transport this food?'])[0]
      if transportation.nil?
        skipped[index] = "missing transportation"
        next
      end
      completed[index] = 0
      date = Date.strptime(row['1. Date of Food Rescue'], '%m/%d/%Y')
      schedule_chain = create_schedule_chain(volunteers, date, transportation, scale)
      schedule_donor = create_schedule_location(schedule_chain, donor)
      create_schedule_location(schedule_chain, recipient)
      create_schedule_parts(schedule_donor, food)
      create_schedule_volunteers(schedule_chain, volunteers)
      log_id = create_log(schedule_chain, date)
      compost_weight = row['10. Weight of food composted (lbs)'].nil? ? 0 : row['10. Weight of food composted (lbs)'].to_d
      food_weight = row['7. Weight of food picked up (lbs)'].nil? ? 0 : row['7. Weight of food picked up (lbs)']
      description = row['9. Summary of food types']
      notes = row['11. Any comments, concerns, notes?']
      hours_spent = row['8. Length of shift (in hours)']
      update_log_parts(log_id, food, food_weight,compost_weight, description)
      populate_log_with_data(log_id, hours_spent, notes, transportation )

    end
    File.open("./lib/tasks/data/completed.json","w") do |f|
      f.write(completed.to_json)
    end
    File.open("./lib/tasks/data/skipped.json","w") do |f|
      f.write(skipped.to_json)
    end
  end
  def get_volunteers(volunteers_names)
    volunteers = volunteers_names.split(/[,]|[:]/)
    volunteer_list = []
    volunteers.each do |vol|
      volunteer = Volunteer.where('name':vol.strip)[0]
      if volunteer.nil?
        volunteer_list = nil
        break
      end
      volunteer_list.append(volunteer)
    end
    volunteer_list
  end

  def create_schedule_chain(volunteers, date, transportation, scale)
    region = Region.where('name': 'TC Food Justice')[0]
    schedule_chain = ScheduleChain.create(
      'detailed_date' => date,
      'transport_type_id' => transportation.id,
      'region_id' => region.id,
      'frequency' => 'one-time',
      'scale_type_id' => scale.id,
      'num_volunteers' => volunteers.length,
    )
    schedule_chain
  end
  
  def create_schedule_parts(schedule, food_type, vendor_id = nil)
    SchedulePart.create(
      'schedule_id' => schedule.id,
      'food_type_id' => food_type.id,
      'location_admin_id' => vendor_id
    )
  end

  def create_schedule_location(schedule_chain, location)
    Schedule.create(
        'schedule_chain_id' => schedule_chain.id,
        'location_id' => location.id
    )
  end

  def create_schedule_volunteers(schedule_chain, volunteers)
    volunteers.each do |vol|
      ScheduleVolunteer.create(
          'volunteer_id' => vol.id,
          'schedule_chain_id' => schedule_chain.id
      )
    end
  end

  def create_log(schedule_chain, date)
    chain = FoodRobot::LogGenerator::ScheduleChainDecorator.new(schedule_chain)
    donor = chain.donors.first
    log = FoodRobot::LogGenerator::LogBuilder.new(date, donor, nil).log
    log.save
    schedule_chain.active = false
    schedule_chain.save
    log.id
  end

  def populate_log_with_data(log_id, hours_spent, notes, transportation)
    log = Log.find(log_id)
    log.update_attributes(
        'hours_spent' => hours_spent,
        'notes' => notes,
        'complete'=>true,
        'transport_type_id' => transportation.id
   )

  end

  def update_log_parts(log_id, food_type, food_weight, compost_weight, description = nil)
    logPart = LogPart.where('log_id':log_id, 'food_type_id': food_type.id)[0]
    logPart.weight = food_weight
    logPart.description = description
    logPart.count = 1
    logPart.compost_weight = compost_weight
    logPart.save
  end

  task :import_volunteers => :environment do
    csv_text = File.read('./lib/tasks/data/TC Food Justice Rescue Log (Responses) For Real - Form Responses 1.csv')
    csv = CSV.parse(csv_text, :headers => true)
    csv.each do |row|
      volunteers = row['2. Names of Volunteers (first, last)'].split(/[,]/)
      volunteers.each do |vol|
        volunteer = Volunteer.where('name':vol.strip)[0]
        next unless volunteer.nil?
          v = Volunteer.create(
              'email' => 'example' + DateTime.now.strftime('%Q') + '@example.com',
              'name' => vol.strip ,
              'assigned' => true,
              'password' => 'changeme!',
              'password_confirmation' => 'changeme!',
          )
          break if v.nil?
          region = Region.where('name': 'TC Food Justice')[0]
          if Region.all.count > 1
            Assignment.create(
                'volunteer_id' => v.id,
                'region_id' => region.id
            )
          end
        
        end
    end
  end

  task :import_locations => :environment do
    csv_text = File.read('./lib/tasks/data/TC Food Justice Rescue Log (Responses) For Real - Form Responses 1.csv')
    csv = CSV.parse(csv_text, :headers => true)
    region = Region.where('name': 'TC Food Justice')[0]
    farmers_market = ["NE Farmer's Market", "Nokomis Farmer's Market"]
    csv.each do |row|
      next if farmers_market.include?(row['3. Where are you picking up from?'])
      donor_name = row['3. Where are you picking up from?']
      donor = Location.where('name': donor_name)[0]
      recipient_name = row['5. What is the drop off location?']
      recipient = Location.where('name': recipient_name)[0]
      if donor.nil?
        Location.create(
            'location_type' => 1,
            'name' => donor_name,
            'active' => true,
            'region_id' => region.id
        )
      end
      if recipient.nil?
         Location.create(
            'location_type' => 0,
            'name' => recipient_name,
            'active' => true,
            'region_id' => region.id
        )
      end
    end
  end

  task :import_farmers_market => :environment do
    csv_text = File.read('./lib/tasks/data/Market Rescues 2016-2017.csv')
    csv = CSV.parse(csv_text, :headers => true)
    vendors_by_name = get_vendors
    region = Region.where('name': 'TC Food Justice')[0]
    csv.each do |row|
      market_name = row['Market']
      market = Location.where('name': market_name)[0]

      if market.nil?
        market = Location.create(
            'location_type' => 1,
            'name' => market_name,
            'active' => true,
            'region_id' => region.id,
            'is_farmer_market' => true
        )
      end
      vendor_name = vendors_by_name[row['Vendor']]
      vendor = LocationAdmin.where('name': vendor_name)[0]
      if vendor.nil?
        market.location_admins.build(
            'name' => vendor_name,
            'email' => 'vendor' + DateTime.now.strftime('%Q') + '@example.com',
            'region_id' => region.id,
            'password' => SecureRandom.hex
        ).save
      else
        if !market.location_admins.include?(vendor)
            market.location_admins << vendor
        end
      end
    end
  end
  task :import_farmers_market_data  => [:environment, :import_farmers_market] do
    csv_text = File.read('./lib/tasks/data/Market Rescues 2016-2017.csv')
    completed_file = File.read('./lib/tasks/data/completed_farmers_market.json')
    csv = CSV.parse(csv_text, :headers => true)
    vendors_by_name = get_vendors
    skipped = {} #keeps track of which rows were skipped due to missing info in the DB
    completed = JSON.parse(completed_file) #keeps track of which rows were successfully added to the db
    index = 1
    food = FoodType.where('name':'Food')[0]
    scale = ScaleType.find(1)
    if food.blank? || scale.blank?
      puts "ERROR! MISSING FOOD TYPES OR SCALE IN DATABASE"
      return
    end
      csv.each do |row|
        index += 1
        next if completed.key?(index.to_s)
        volunteers = get_volunteers(row['Volunteers'])
        if volunteers.nil?
          skipped[index] = "missing volunteer"
          next
        end
        donor = Location.where('name': row['Market'])[0]
        vendor = LocationAdmin.where('name': vendors_by_name[row['Vendor']])[0]
        if donor.nil?
          skipped[index] = "missing donor"
          next
        end
        if vendor.nil?
          skipped[index] = "missing vendor"
          next
        end
        recipient = Location.where('name': row['Recipient'])[0]
        if recipient.nil?
          skipped[index] = "missing recipient"
          next
        end
        transportation = TransportType.where('name': row['Transport'])[0]
        if transportation.nil?
          skipped[index] = "missing transportation"
          next
        end
        completed[index] = 0
        date = Date.strptime(row['Date'], '%m/%d/%Y')
        schedule_chain = create_schedule_chain(volunteers, date, transportation, scale)
        schedule_donor = create_schedule_location(schedule_chain, donor)
        create_schedule_location(schedule_chain, recipient)
        create_schedule_parts(schedule_donor, food, vendor.id)
        create_schedule_volunteers(schedule_chain, volunteers)
        log_id = create_log(schedule_chain, date)
        compost_weight = 0
        food_weight = row['Weight'].nil? ? 0 : row['Weight']
        description = row['Description']
        notes = ''
        hours_spent = row['Length']
        update_log_parts(log_id, food, food_weight,compost_weight, description)
        populate_log_with_data(log_id, hours_spent, notes, transportation )

      end
      File.open("./lib/tasks/data/completed_farmers_market.json","w") do |f|
        f.write(completed.to_json)
      end
      File.open("./lib/tasks/data/skipped_farmers_market.json","w") do |f|
        f.write(skipped.to_json)
      end
    end


  def get_vendors
    csv_text = File.read('./lib/tasks/data/vendors_code.csv')
    csv = CSV.parse(csv_text, :headers => true)
    vendors_by_name = {}
    csv.each do |row|
      vendors_by_name[row['Code']] = row['Vendor']
    end
    vendors_by_name
  end

end
