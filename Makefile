devserver:
	bundle exec thin -e development start
prodserver:
	bundle exec thin -e production start
prodbounce:
	sudo /usr/bin/ruby1.9.1 /usr/bin/thin restart -C /etc/thin1.9.1/bfr.yml
datasync:
	ssh erichtho "pushd /var/www/bfr/bfr-webapp/;sudo chmod 777 log/development.log;bundle exec rake db:data:dump"
	scp erichtho:/var/www/bfr/bfr-webapp/db/data.yml db/
	rake db:data:load
