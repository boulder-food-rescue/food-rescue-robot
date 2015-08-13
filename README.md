# What is this thing?

The Food Rescue Robot is a Rails 3 web application for managing the logistics
of just-in-time (i.e., warehouse-less) food rescue. It keeps track of donors,
recipients, a pickup and delivery schedule, and all the volunteers responsible
for doing the work. It sends reminders to users about their pickups. The site 
also logs how much food is rescued, and can automatically issue receipts for donations.

# Who uses it? (And how can I?)

Currently, the "Food Rescue Robot" is live at http://robot.boulderfoodrescue.org
and is used by 10 cities around the world. If you're keen to use it, shoot an email to caleb at boulder food rescue (dot) org, and I can set you up with an account. Alternatively, if you would like to fork the source and hack on it yourself you are welcome to. This code is licensed under a Beerware-style license:

  As long as you retain this notice you can do whatever you want with this stuff.
  If we meet some day, and you think this stuff is worth it, you can buy me a
  beer in return.

# Who is responsible?

Most of the site was written by Caleb Phillips, a co-founder of Boulder Food Rescue (http://www.boulderfoodrescue.org) and
adjunct Computer Science professor at the University of Colorado, Boulder. There is a fork maintained in Boston by
Rahul Bhargava (MIT Media Labs), and some early design work was done by University of Colorado interns Sean Weise
and Zac Doyle under awards from the Casey Feldman Foundation.

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

 * Ruby 1.9.3
 * Rails 3.2.16 and the rest of the dependencies in the Gemfile
 * Postgresql 9.3 or greater (runs on at least 9.4.4)
 * A reasonable operating system (e.g., Linux)
 * Various dependencies for the above

## Database

You'll need to create a database and user:

```
$ sudo su - postgres
$ psql
> CREATE DATABASE robot_db;
> CREATE ROLE robot_user WITH LOGIN PASSWORD 'changeme';
> GRANT ALL ON DATABASE robot_db TO robot_user;
> \q
$ exit
```

Next, copy /config/database.yml.dist to /config/database.yml and make any necessary changes.

If you want to start with an empty schema, you can proceed as usual (rake db:setup, etc.), or you can
load a database dump from me or elsewhere. If you start with an empty schema, you'll want to start
by creating a Volunteer user with the admin bit set, and a first region e.g.:

```
$ rails console
> r = Region.new
> r.name = "Somewhere"
> r.save
>
> v = Volunteer.new
> v.email = "jane.doe@gmail.com"
> v.password "changeme"
> v.admin = true
> v.regions << r
> v.save
```

## Running It

You should be able to simply:

```
$ make devserver
```

This starts a thin server on localhost:3000, which you can get at with your browser.

Also, beware that some crucial functions, like generating log entries from the schedule, and sending emails
are executed by cron, daily or weekly. If you want to work on those bits, you may be keen to run these:

```
bundle exec rake foodrobot:generate_logs
bundle exec rake foodrobot:send_reminders
bundle exec rake foodrobot:send_weekly_summary
```
