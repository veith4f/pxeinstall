.PHONY: default
default:
	@[ -f tftp/netboot.efi.signed ] || (echo Please generate boot files and copy to tftp dir to run tests. && exit 1)
	docker-compose build
	docker-compose up
