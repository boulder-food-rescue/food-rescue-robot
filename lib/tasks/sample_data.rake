namespace :db do
  desc "Fill database with sample data"
  task :populate => :environment do
    boulder = Region.where(name: "Boulder").first_or_initialize
    boulder.save

    admin = Volunteer.where(email: 'volunteer@example.com').first_or_initialize do |v|
      v.password = 'changeme'
      v.admin = true
      v.regions << boulder
      v.assigned = true
    end
    admin.save
  end
end
