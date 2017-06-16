LUA_PATH="./lib/?.lua;;"

test:
	prove -Ilib

docker-test:
	@echo "========= docker build... ============"
	@docker build -t local/openresty-querymask-develop .
	@echo "========= docker run... ============"
	@docker run -v $(PWD):/code -it local/openresty-querymask-develop /bin/bash -c 'make test'

.PHONY: test docker-test
