
ifneq (,$(wildcard .env.example))
    include .env.example
    export $(shell sed 's/=.*//' .env.example)
endif

ifeq ($(shell uname), Darwin)
	SED_INPLACE_FLAG=-i ''
	XDEBUG_CLIENT_HOST := host.docker.internal
else
	SED_INPLACE_FLAG=-i
	XDEBUG_CLIENT_HOST := $(shell hostname -I | cut -d" " -f1)
endif

install: \
	install-docker-env-file \
	install-docker-compose-override \
	install-php-ini-files \
	install-nginx-conf \
	install-docker-build \
	install-composer-packages \
	install-app-env-file \
	install-database \
	start

test:
	cd ./docker && docker compose run --rm -u www-data -it php sh -c "composer qa"

clean:
	cd ./docker && docker compose down -v
	git clean -fdx -e .idea

### install parts

install-docker-env-file:
	cp -f .env.example .env

install-docker-compose-override:
	cp -f ./docker/compose.override.yml.example ./docker/compose.override.yml
	sed $(SED_INPLACE_FLAG) "s/HOST_UID:.*/HOST_UID: $(shell id -u)/" ./docker/compose.override.yml

install-php-ini-files:
	cp -f ./docker/php/assets/php.ini.example ./docker/php/assets/php.ini
	cp -f ./docker/php/assets/xdebug.ini.example ./docker/php/assets/xdebug.ini
	sed $(SED_INPLACE_FLAG) "s/XDEBUG_CLIENT_HOST/${XDEBUG_CLIENT_HOST}/" ./docker/php/assets/xdebug.ini

install-nginx-conf:
	cp -f ./docker/nginx/conf.d.example ./docker/nginx/conf.d

install-docker-build:
	cd ./docker && \
	docker compose build

install-composer-packages:
	cd ./docker && \
	docker compose run --rm -u www-data -it php sh -c "composer install"

install-app-env-file:
	cp -f .env.example .env

install-database:
	cd ./docker && \
	docker compose up -d mysql && \
	docker run --rm --network $(APP_NAME)_network jwilder/dockerize -wait tcp://mysql:3306 -timeout 100s

### commands

terminal:
	docker exec -it -u www-data -e XDEBUG_MODE=off $(APP_NAME) sh -l

qa:
	docker exec -it -u www-data -e XDEBUG_MODE=off $(APP_NAME) composer qa

start:
	cd ./docker && \
	docker compose up -d
	@echo "Your application is available at: http://localhost:8080"

stop:
	cd ./docker && \
	docker compose stop
