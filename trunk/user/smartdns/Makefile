SRC_NAME = smartdns-Release31
THISDIR = $(shell pwd)

all: smartdns_dl extract_test config_test
	$(MAKE) -C $(SRC_NAME)

smartdns_dl:
	( if [ -d smartdns ]; then \
		tar zcf smartdns.tar.gz smartdns ; \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		tar zxf $(SRC_NAME).tar.gz ; \
	fi )

config_test:
	( if [ -f ./config_done ]; then \
		echo "the same configuration"; \
	else \
		touch config_done; \
	fi )

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) clean ; \
	fi ; \
	rm -f config_done

romfs:
	chmod -R +x ./smartdns
	$(ROMFSINST) -p +x $(THISDIR)/$(SRC_NAME)/src/smartdns /usr/bin/smartdns
	$(ROMFSINST) -p +x $(THISDIR)/smartdns.sh /usr/bin/smartdns.sh
	$(ROMFSINST) $(THISDIR)/Advanced_smartdns.asp /www/Advanced_smartdns.asp
	$(ROMFSINST) $(THISDIR)/smartdns.tar.gz /etc_ro/smartdns.tar.gz
