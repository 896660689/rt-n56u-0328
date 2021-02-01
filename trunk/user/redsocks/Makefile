SRC_NAME=redsocks-release-0.5-11-g19b822e
SRC_URL=https://github.com/SuzukiHonoka/redsocks_for_mipsel/releases/download/release-0.5-11-g19b822e/redsocks

THISDIR = $(shell pwd)

all: download_test

download_test:
	( if [ ! -f redsocks ]; then \
		wget -t5 --timeout=20 --no-check-certificate -O redsocks $(SRC_URL); \
	fi )

romfs:
	cp -fP $(STAGEDIR)/lib/libevent_core-2.1.so.* $(ROMFSDIR)/lib
	$(ROMFSINST) -p +x $(THISDIR)/redsocks /usr/bin/redsocks
