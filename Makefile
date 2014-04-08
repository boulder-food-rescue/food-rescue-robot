devserver:
	bundle exec thin -e development start
prodserver:
	bundle exec thin -e production start
datasync:
	ssh erichtho "pushd /var/www/bfr/bfr-webapp/;sudo chmod 777 log/development.log;rake db:data:dump"
	scp erichtho:/var/www/bfr/bfr-webapp/db/data.yml db/
	rake db:data:load
