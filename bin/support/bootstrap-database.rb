# frozen_string_literal: true

def run_command(*args)
  command = args.join(" ")
  puts command
  system(command)
end

def locate_psql_command
  bin_location = `command -v psql`.strip

  if bin_location.empty?
    puts <<~WARNING
==> Error: database connection could not be established and "psql" command could
    not be found. Do you have Postgres installed?
    WARNING
    exit 1
  end

  bin_location
end

def each_sql_statement
  ActiveRecord::Base.configurations.each_value do |settings|
    database = settings.fetch('database')
    username = settings.fetch('username')
    password = settings['password']

    # Create the database user
    create_role_clauses = ["CREATE ROLE", username]

    if password
      create_role_clauses.concat!("WITH PASSWORD", password)
    else
      create_role_clauses << "WITH LOGIN"
    end

    yield create_role_clauses.join(' ') + ";"

    # Create the database
    yield "CREATE DATABASE #{database} OWNER #{username};"
  end
end

def create_database
  puts "Attempting to bootstrap database:"

  psql_command = locate_psql_command

  each_sql_statement do |statement|
    run_command(psql_command, "-c #{statement.inspect}")
  end

  begin
    ActiveRecord::Base.connection.reconnect!
  rescue PG::ConnectionBad => error
    puts "Database creation failed: #{error}"
    exit 1
  end
end

begin
  require_relative '../../config/environment'
rescue PG::ConnectionBad => error
  puts "Connection could not be established."
  create_database
end
