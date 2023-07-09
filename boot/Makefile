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
	@cp conf/gpg.cfg-template conf/gpg.cfg
	@cat conf/grub.cfg-template | \
	sed 's|^  linux.*|  linux vmlinuz hostconf=https://$$\{net_default_server\} \
		client=$$\{net_default_mac\} console=ttyS0 insecure|g' > conf/grub.cfg

.PHONY: default
default:
	docker-compose build
	docker-compose up
