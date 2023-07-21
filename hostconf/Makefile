.DEFAULT_GOAL := default

.PHONY: build
build:
	@cp docker-compose.override.yml-template docker-compose.override.yml
	@docker compose build
	@rm docker-compose.override.yml

.PHONY: default
default:
	@[ ! -z "$(shell docker images | grep hostconf-hostconf)" ] || \
		(cp docker-compose.override.yml-template docker-compose.override.yml \
		&& docker compose build \
		&& rm docker-compose.override.yml)
	@docker compose up

.PHONY: start
start:
	@docker compose build
	@docker compose start

.PHONY: stop
stop:
	@docker compose stop