SRC_NAME=redsocks-19b822e
SRC_URL=https://github.com/SuzukiHonoka/redsocks_for_mipsel/releases/download/release-0.5-11-g19b822e/redsocks

THISDIR = $(shell pwd)

all: download_test
	$(MAKE) -C $(SRC_NAME)

download_test:
	( if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) clean ; \
	fi )

romfs:
	$(ROMFSINST) $(THISDIR)/$(SRC_NAME)/redsocks /usr/bin/redsocks
	cp -fP $(STAGEDIR)/lib/libevent_core-2.1.so.* $(ROMFSDIR)/lib
