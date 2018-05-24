# frozen_string_literal: true

require 'sample_data'

namespace :db do
  desc 'Create a sample region in the database'
  task :sample_region => :environment do
    Faker::Config.locale = 'en-US'
    region = SampleData.create_region

    puts <<-EOF.strip_heredoc
      ---------
      Created region ##{region.id}: '#{region.name}'"
        with admin(s): #{region.volunteers.where(assignments: { admin: true }).map(&:email).join(', ')}"

      Run `rake foodrobot:generate_logs` to generate log records for the newly created schedule chains.
    EOF
  end
end
