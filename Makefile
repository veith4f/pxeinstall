.PHONY: test
test:
	@cd boot && make config && make keys && make
	@rm -Rf test/tftp && mkdir test/tftp && cp boot/output/* test/tftp
	@cd test && make
