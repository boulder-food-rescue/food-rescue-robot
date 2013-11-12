devserver:
	bundle exec thin -e development start
prodserver:
	bundle exec thin -e production start
