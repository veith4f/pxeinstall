.DEFAULT_GOAL := default

SUBJ="/CN=John Doe,O=Company/"
VALIDITY=3650

.PHONY: keys
keys:
	@[ -f "$(shell which openssl)" ] || (echo "Please install 'openssl' to generate certificates." && exit 1)
	@[ -f "sbkeys/db.key" ] || openssl req -new -x509 \
		-newkey rsa:2048 -subj $(SUBJ) -keyout sbkeys/db.key \
		-out sbkeys/db.crt -days $(VALIDITY) -nodes -sha256

.PHONY: config
config:
	@[ -f "conf/gpg.cfg" ] || cp conf/gpg.cfg-template conf/gpg.cfg
	@[ -f "conf/grub.cfg" ] || cp conf/grub.cfg-template conf/grub.cfg

.PHONY: default
default:
	@docker-compose build
	@docker-compose up
