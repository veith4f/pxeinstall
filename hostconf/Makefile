.DEFAULT_GOAL := default

.PHONY: cert
cert:
	@([ ! -f ./cert/key.pem ] || [ ! -f ./cert/cert.pem ]) && openssl req -newkey rsa:2048 \
			-new -nodes -x509 -days 3650 -keyout cert/key.pem -out cert/cert.pem \
			-subj "/CN=hostconf.domain.tld/C=DE/O=Sopra Steria SE/" || true

.PHONY: default
default:
	docker-compose build
	docker-compose up
