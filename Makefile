logs:
	rake foodrobot:generate_logs
devserver:
	bundle exec thin -e development start
prodserver:
	bundle exec thin -e production start
prodbounce:
	sudo chmod -R 777 tmp public log
	sudo chown -R www-data public tmp log
	bundle exec rake assets:precompile RAILS_ENV=development
	sudo /usr/bin/ruby1.9.1 /usr/bin/thin restart -C /etc/thin1.9.1/bfr.yml
datasync:
	ssh erichtho.smallwhitecube.com "pushd /var/www/bfr/bfr-webapp/;sudo chmod 777 log/development.log;bundle exec rake db:data:dump"
	scp erichtho.smallwhitecube.com:/var/www/bfr/bfr-webapp/db/data.yml db/
	sudo chmod 777 /var/www/bfr-webapp/log/development.log
	rake db:data:load
