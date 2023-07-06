.DEFAULT_GOAL := default
.ONESHELL: cert
LOCALIP="$(shell ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.*' | awk '{print $1}')"

.PHONY: cert
cert:
	@([ ! -f ./cert/key.pem ] || [ ! -f ./cert/cert.pem ]) && openssl req -newkey rsa:2048 \
			-new -nodes -x509 -days 3650 -keyout cert/key.pem -out cert/cert.pem \
			-subj "/CN=hostconf.domain.tld/C=DE/O=Sopra Steria SE/" \
			-addext "subjectAltName=DNS:hostconf.domain.tld,DNS:*.domain.tld,IP:$(LOCALIP)" \
			|| true

.PHONY: default
default:
	docker-compose build
	docker-compose up
