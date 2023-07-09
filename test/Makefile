.DEFAULT_GOAL := default

.PHONY: generate
generate:
	@cd ../boot && ([ ! -f conf/grub.cfg ] || cp conf/grub.cfg conf/_grub.cfg) && \
		cat conf/grub.cfg-template | \
			sed 's|^  linux.*|  linux vmlinuz hostconf=https://$$\{net_default_server\} \
			client=$$\{net_default_mac\} console=ttyS0 insecure|g' > conf/grub.cfg && \
		make keys && make && cp output/* ../test/tftp && \
			([ ! -f conf/_grub.cfg ] || mv conf/_grub.cfg conf/grub.cfg)

.PHONY: default
default:
	@[ -f tftp/netboot.efi.signed ] || (echo Please run 'make generate' to generate boot files for testing. && exit 1)
	@cd ../hostconf && make start
	@docker-compose build
	@docker-compose up
	@cd ../hostconf && make stop
