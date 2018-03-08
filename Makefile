logs:
	rake foodrobot:generate_logs
devserver:
	bundle exec thin -e development start
prodserver:
	bundle exec thin -e production start
datasync:
	heroku pg:backups capture
	curl -o latest.dump `heroku pg:backups public-url`
	pg_restore --verbose --clean --no-acl --no-owner -h localhost -U bfr_user -d bfr_db latest.dump
