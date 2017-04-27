# What is this thing?

The Food Rescue Robot is a Rails 3 web application for managing the logistics
of just-in-time (i.e., warehouse-less) food rescue. It keeps track of donors,
recipients, a pickup and delivery schedule, and all the volunteers responsible
for doing the work. It sends reminders to users about their pickups. The site
also logs how much food is rescued, and can automatically issue receipts for donations.

# Who uses it? (And how can I?)

Currently, the "Food Rescue Robot" is live at http://robot.boulderfoodrescue.org
and is used by a number of food rescue organizations cities around the world. If you're keen to use it, shoot an email to caleb at boulder food rescue (dot) org, and I can set you up with an account. Alternatively, if you would like to fork the source and hack on it yourself you are welcome to. This code is licensed under a Beerware-style license:

  As long as you retain this notice you can do whatever you want with this stuff.
  If we meet some day, and you think this stuff is worth it, you can buy me a
  beer in return.

# Who is responsible?

Most of the code was written by Caleb Phillips, a co-founder of Boulder Food Rescue (http://www.boulderfoodrescue.org) and
adjunct Computer Science professor at the University of Colorado, Boulder. There is a fork maintained in Boston by
Rahul Bhargava (MIT Media Labs), and some early design work was done by University of Colorado interns Sean Weise
and Zac Doyle under awards from the Casey Feldman Foundation. As of May 2016, Rylan Bowers (http://rylanbowers.com/) is leading
development on the master branch and we are growing a small team of hackers to maintain and improve the codebase.

# How can I help?

If you want to help with development, feel free to fork the project. If you have something
to submit upstream, send a pull request from your fork. If you're trying to setup a dev environment, keep reading.

# General Tech Overview

The software's main goal is to keep a record of what food got picked up, when, and by
whom and, to some degree, where it was delivered. The key database relations are:

  * Logs - history of what was picked up, when, how and by whom. Log entries are generated from the schedule three days in advance.
  * Schedule Chains - Schedule of each route, where food is taken from one or more donors and given to one or more recipients
  * Locations - Donors or recpients, places where food comes from or goes to
  * Volunteers - The main user table, which authentication happens against
  * Regions - Keeps, e.g., Denver's stuff separate from Seattle's stuff

Besides that, there are some secondary relationships:

  * Food Types - e.g., produce or bakery
  * Transport Types - e.g., bike or car
  * Scale Types - e.g., floor scale or bathroom scale
  * Absences - tracks when volunteers leave
  * Assignments - list of which region each volunteer belongs to
  * Cell Carriers - hacky way to do email->sms that should be replaced

Functionally, the app works as you would expect. It's a MVC-paradigm app in the traditional Rails 3 sense. There is
minimal front-end interaction and very little javascript outside of a few basic JQuery things and stuff like
Datatables, Highcharts, and Select2.

There is a basic JSON API, which is provided by some controller methods (look for ```responds_to :json```). You
can see the routes with ```rake routes```;

# Preparing a Development Environment

## Prerequisites

 * Ruby 2.1
 * Rails 3.2.16 and the rest of the dependencies in the Gemfile
 * Postgresql 9.3 or greater (runs on at least 9.4.4)
 * A reasonable operating system (e.g., Linux or Mac, Windows if you're saucy)
 * Various dependencies for the above


## Setup

1. **Clone the repository to your machine.**


  ```
  git clone https://github.com/boulder-food-rescue/food-rescue-robot.git
  cd food-rescue-robot
  bundle install
  ```
2. **You'll need to create a database and user:**

  ```
  $ sudo su - postgres
  $ psql
  > CREATE DATABASE bfr_webapp_db;
  > CREATE ROLE bfr_webapp_user WITH LOGIN PASSWORD 'changeme';
  > GRANT ALL ON DATABASE bfr_webapp_db TO bfr_webapp_user;
  > \q
  $ exit
  ```

3. **Copy `database.yml.dist`**

  ```
  cp config/database.yml.dist config/database.yml
  ```

4. **Setup `config/database.yml` to look like:**

  ```
  test:
    adapter: postgresql
    database: bfr_webapp_db_test
    host: localhost
    pool: 5
    timeout: 5000

  development:
    adapter: postgresql
    database: bfr_webapp_db
    host: localhost
    pool: 5
    timeout: 5000

  production:
    adapter: postgresql
    database: bfr_webapp_db
    username: bfr_webapp_user
    password: CHANGEME
    host: localhost
    pool: 5
    timeout: 5000
  ```
  **Warning:** _The database defined as "test" will be erased and re-generated from your  development database when you run "rake". Do not set this db to the same as development or  production._

5. **Create database:**

  ```
  bundle exec rake db:create
  ```

6. **If you receive an encoding error, go to db console and:**

  ```
  SET CLIENT_ENCODING TO 'WIN1252';
  ```

7. **Load Database Schema:**

  ```
  bundle exec rake db:schema:load
  ```

  **Warning:** _`bundle exec rake db:migrate` currently does not work due to default scopes an improper order of columns added to the database with migrations._

8. **Seed:**

  ```
  bundle exec rake db:seed
  ```
  **Note:** _This creates an admin volunteer and other required bits. You should look it over._

9. **Prepare Testing:**

  ```
  bundle exec rake db:test:prepare
  ```

## Running It

You should be able to simply:

  $ make devserver

or

  $ bundle exec rails server


This starts a thin server on localhost:3000, which you can get at with your browser.

Also, beware that some crucial functions, like generating log entries from the schedule, and sending emails
are executed by cron, daily or weekly. If you want to work on those bits, you may be keen to run these:

```
bundle exec rake foodrobot:generate_logs
bundle exec rake foodrobot:send_reminders
bundle exec rake foodrobot:send_weekly_summary
```

## Generating Sample Data

The seeds command generates a regular volunteer and an admin volunteer for you. Please review seeds.rb. You can make more regions / volunteers with this code:

```
$ rails console
region = Region.create(name: "Boulder")

volunteer = Volunteer.new(email: "you.email@gmail.com", password: "changeme", password_confirmation: "changeme", assigned: true)
volunteer.admin = true
volunteer.regions << region
volunteer.save!
```

**Additionally:**

Run:

  bundle exec rake db:sample_region

**Note:** _Running the `db:sample_region` rake task will create a new `Region` in your database and populate it with a bunch of random data (volunteers, donors, recipients, schedule chains, etc.). For more info on what exactly is created, see `lib/sample_data/region_data.rb`._

**Note:** _Region admins will be created for the new region with email addresses based on the region's name. For example, if the region name is `San Francisco`, the created region admins will have email addresses: `admin-san-francisco@example.com`, `admin-san-francisco-2@example.com`, etc. Their passwords will all be `password`._

**Note:** _The `db:sample_region` rake task does not create any `Log` records, so you'll have to run the rake task to generate logs based on the newly created schedule chains: `bundle exec rake foodrobot:generate_logs`._

## Hosting

The current production version is hosted via Heroku, collaborators can push to/pull from Heroku once their repository has been setup. To do this, first install the Heroku tool belt, then add the remote git location:

```
$ heroku git:remote -a boulder-food-rescue-robot
```

You can pull a copy of the current live database with these commands ('make datasync' will also do this):

```
$ heroku pg:backups capture
$ curl -o latest.dump `heroku pg:backups public-url`
$ pg_restore --verbose --clean --no-acl --no-owner -h localhost -U robot_user -d robot_db latest.dump
```
