devserver:
	bundle exec thin -e development start
prodserver:
	bundle exec thin -e production start
prodbounce:
	sudo /usr/bin/ruby1.9.1 /usr/bin/thin restart -C /etc/thin1.9.1/bfr.yml
