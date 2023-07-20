.DEFAULT_GOAL := default

.PHONY: cert
cert:
	@[ -f "$(shell which openssl)" ] || (echo "Please install 'openssl' to generate certificates." && exit 1)
	@[ ! -f ./cert/key.pem ] || [ ! -f ./cert/cert.pem ] && openssl req -newkey rsa:2048 \
			-new -nodes -x509 -days 3650 -keyout cert/key.pem -out cert/cert.pem \
			-subj "/CN=hostconf.domain.tld/" || true

.PHONY: build
build:
	@cp docker-compose.override.yml-template docker-compose.override.yml
	@docker-compose build
	@rm docker-compose.override.yml


.PHONY: default
default:
	@[ ! -z "$(shell docker images | grep hostconf-hostconf)" ] || \
		(cp docker-compose.override.yml-template docker-compose.override.yml \
		&& docker-compose build \
		&& rm docker-compose.override.yml)
	@docker-compose up

.PHONY: start
start:
	docker-compose build
	docker-compose start

.PHONY: stop
stop:
	docker-compose stop