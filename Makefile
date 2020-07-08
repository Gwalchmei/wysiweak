.PHONY: clean

install: package.json
	yarn

serve: install
	yarn serve

clean:
	rm -rf node_modules
	rm -rf second-app/node_modules