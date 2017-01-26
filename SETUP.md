###
1. Clone the repository to your machine.
```
git clone https://github.com/boulder-food-rescue/food-rescue-robot.git
cd food-rescue-robot
bundle install
```

2. Copy `database.yml.dist`
```
cp config/database.yml.dist config/database.yml
```

3. Setup `config/database.yml` to look like:

```
# Warning: The database defined as "test" will be erased and
# re-generated from your development database when you run "rake".
# Do not set this db to the same as development or production.
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


5. Prepare postgres
```
initdb bfr-data/
```

  * If you have an existing database by chance,
```
ps aux | grep postgres
kill -9 (number from below)
```
*Number of whatever process is looks like:
```
username       (use this number)   0.0  0.0  2613116   3576   ??  S     5:12AM   0:05.17 /Applications/Postgres.app/Contents/Versions/9.6/bin/postgres -D /Users/tmikeschutte/Library/Application Support/Postgres/var-9.6 -p 5432
```

7. Run the db server:
```
postgres -D bfr-data/
```

8. In a new terminal tab/window:
```
rake db:{create,setup}
```

9. If you receive an encoding error, go to db console and:
```
SET CLIENT_ENCODING TO 'WIN1252';
```

