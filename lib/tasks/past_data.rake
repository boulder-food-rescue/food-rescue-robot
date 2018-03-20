require 'csv'
require 'json'

namespace :past_data do
  task :import_past_data => :environment  do
    csv_text = File.read('./lib/tasks/tcFoodJusticDataSample.csv')
    completed_file = File.read('./lib/tasks/completed.json')
    csv = CSV.parse(csv_text, :headers => true)
    skipped = {} #keeps track of which rows were skipped due to missing info in the DB
    completed = JSON.parse(completed_file) #keeps track of which rows were successfully added to the db
    index = 0
    compost = FoodType.where('name':'Compost')[0]
    food = FoodType.where('name':'Food')[0]
    scale = ScaleType.find(1)
    if compost.blank? || food.blank? || scale.blank?
      puts "ERROR! MISSING FOOD TYPES OR SCALE IN DATABASE"
      return
    end
    csv.each do |row|
      index += 1
      next if completed.key?(index.to_s)
      volunteers = get_volunteers(row['Names_of_Volunteers'])
      if volunteers.nil?
        skipped[index] = "missing volunteer"
        next
      end
      donor = Location.where('name': row['Where_are_you_picking_up_from'])[0]
      if donor.nil?
        skipped[index] = "missing donor"
        next
      end
      recipient = Location.where('name': row['What_is_the_drop_off_location'])[0]
      if recipient.nil?
        skipped[index] = "missing recipient"
        next
      end
      transportation = TransportType.where('name': row['How_did_you_transport_this_food'])[0]
      if transportation.nil?
        skipped[index] = "missing transportation"
        next
      end
      completed[index] = 0
      date = Date.strptime(row['Date_of_Food_Rescue'], '%m/%d/%Y')
      schedule_chain = create_schedule_chain(volunteers, date, transportation, scale)
      schedule_donor = create_schedule_location(schedule_chain, donor)
      create_schedule_location(schedule_chain, recipient)
      create_schedule_parts(schedule_donor, food)
      create_schedule_parts(schedule_donor, compost)
      create_schedule_volunteers(schedule_chain, volunteers)
      log_id = create_log(schedule_chain, date)
      compost_weight = row['Weight_of_food_composted'].to_d
      food_weight = row['Weight_of_food_picked_up'].to_d - compost_weight
      description = row['Summary_of_food_types']
      notes = row['Any_comments']
      hours_spent = row['Length_of_shift']
      update_log_parts(log_id, food, food_weight,description)
      update_log_parts(log_id, compost, compost_weight)
      populate_log_with_data(log_id, hours_spent, notes, transportation )

    end
    File.open("./lib/tasks/completed.json","w") do |f|
      f.write(completed.to_json)
    end
    File.open("./lib/tasks/skipped.json","w") do |f|
      f.write(skipped.to_json)
    end
  end
  def get_volunteers(volunteers_names)
    volunteers = volunteers_names.split(/[,]|and/)
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
    region = Region.where('name': 'Boulder Food Rescue')[0]
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
  
  def create_schedule_parts(schedule, food_type)
    SchedulePart.create(
      'schedule_id' => schedule.id,
      'food_type_id' => food_type.id
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

  def update_log_parts(log_id, food_type, food_weight, description = nil)
    logPart = LogPart.where('log_id':log_id, 'food_type_id': food_type.id)[0]
    logPart.weight = food_weight
    logPart.description = description
    logPart.count = 1
    logPart.save
  end

  task :import_volunteers => :environment  do
    csv_text = File.read('./lib/tasks/tcFoodJusticData.csv')
    csv = CSV.parse(csv_text, :headers => true)
    csv.each do |row|
      volunteers = row['Names_of_Volunteers'].split(/[,]|and/)
      volunteers.each do |vol|
        volunteer = Volunteer.where('name':vol.strip)[0]
        if volunteer.nil?
          v = Volunteer.create(
              'email' => 'example' + Date.today.to_s + '@example.com',
              'name' => vol,
              'assigned' => true
          )
          region = Region.where('name': 'Boulder Food Rescue')[0]
          Assignment.create(
              'volunteer_id' => v.id,
              'region_id' => region.id

          )
        end


      end

    end
  end

end
