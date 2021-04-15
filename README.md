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

Alternatively, if your OSS time is limited, you can [donate to Boulder Food Rescue](https://www.boulderfoodrescue.org/donate/) via several options. _Please include a note that indicates you are donating for Robot Development in the notes._

[<img src="https://www.boulderfoodrescue.org/wp-content/uploads/2011/09/partnership_donatebutton.jpg">](https://www.coloradogives.org/index.php?section=organizations&action=newDonation&fwID=37126)

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

 * Ruby 2.3.7
 * Postgresql 9.3 or greater (runs on at least 9.4.4)
 * A reasonable operating system (e.g., Linux or Mac, Windows if you're saucy)
 * Various dependencies for the above

*Detailed instructions for setting up prerequisites on a Mac platform are below. 

## Setup

Clone this repository:

    git clone https://github.com/boulder-food-rescue/food-rescue-robot.git

`cd` into the directory:

    cd food-rescue-robot
### Linux or Mac

#### Configuring 'prerequisites'

 * Ruby 2.3.7:
 
 You will need to have 'gpg tools' for the next step; use the command `brew install gnupg` to install it (if you have homebrew). To download it from source, refer to https://gnupg.org/download/index.html
 
[Install RVM](https://rvm.io/rvm/install):
 
    gpg --keyserver hkp://pool.sks-keyservers.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
 
    \curl -sSL https://get.rvm.io | bash -s stable
    
 Install OpenSSL: `rvm pkg install openssl`
 
 Finally, install Ruby 2.3.7:
 
    rvm install ruby-2.3.7 --with-openssl-dir=$rvm_path/usr
    
 * PostgreSQL: 

  Although not the only option, it may be easiest to handle this requirement using Postgres.app: https://postgresapp.com/

#### Set up your environment:

    bundle exec bin/setup

This will check your system for prerequisites (e.g. Ruby version), install dependencies, create a `.env` file, create any missing databases and database users, load the database schema and seed development data.

You may need to insert the secret key manually. Check the `.env` file's SECRET_KEY_BASE. If absent, generate a secret key by using the command below:

`bundle exec rake secret`

### Manual or Windows

Install dependencies:

    bundle install

Copy `.env.example` to `.env`, and replace `SECRET_KEY_BASE` with the value of:

    rake secret

Create a development and test Postgres database and user:

```sql
CREATE ROLE bfr_webapp_db WITH LOGIN;
CREATE ROLE bfr_webapp_db_test WITH LOGIN;
CREATE DATABASE bfr_webapp_db OWNER bfr_webapp_db;
CREATE DATABASE bfr_webapp_db_test OWNER bfr_webapp_db_test;
```

Load the database
## Running It

To start a server, run

    bundle exec rails server

Open [http://localhost:3000](http://localhost:3000)

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

  ```
  $ bundle exec rake db:sample_region
  ```

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

## Troubleshooting

### Logs

Having trouble with logs not being generated for schedule chains?
  - Check that ALL locations (also called donors) are valid. Often times this causes logs to not be created for current shifts/schedule chains being run.
