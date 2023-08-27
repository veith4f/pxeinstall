.DEFAULT_GOAL := default

SUBJ="/CN=John Doe,O=Company/"
VALIDITY=3650

.PHONY: sbkeys
sbkeys:
	@[ -f "$(shell which openssl)" ] || (echo "Please install 'openssl' to generate certificates." && exit 1)
	@[ -f "sbkeys/db.key" ] || openssl req -new -x509 \
		-newkey rsa:2048 -subj $(SUBJ) -keyout sbkeys/db.key \
		-out sbkeys/db.crt -days $(VALIDITY) -nodes -sha256

.PHONY: config
config:
	@[ -f "conf/gpg.cfg" ] || cp conf/gpg.cfg-template conf/gpg.cfg
	@[ -f "conf/grub.cfg" ] || cp conf/grub.cfg-template conf/grub.cfg

.PHONY: build
build:
	@docker build buildenv -t sopra/ipl/pxe-boot:1.0

.PHONY: default
default:
	@[ ! -z "$(shell docker images | grep sopra/ipl/pxe-boot)" ] || make build
	@docker compose up buildenv

.PHONY: test
test:
	@[ -f output/netboot.efi.signed ] || (echo Please run 'make' to generate required files for testing. && exit 1)
	@[ -f conf/grub.cfg ] || cp conf/grub.cfg-template conf/grub.cfg 
	@grep -q "console=ttyS0" conf/grub.cfg || (echo Please rebuild boot files with 'console=ttyS0' added to kernel cmdline in grub.cfg. && exit 1)
	@docker-compose up test

