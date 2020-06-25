THISDIR := $(shell pwd)

all: unblockmusic_dl

unblockmusic_dl:
	( if [ -d unblockmusic ]; then \
		tar zcf unblockmusic.tar.gz unblockmusic ; \
	fi )

download_test:

extra_test:

clean:

romfs:
	chmod -R +x ./unblockmusic
	$(ROMFSINST) -p +x $(THISDIR)/unblockmusic.sh /usr/bin/unblockmusic.sh
	$(ROMFSINST) $(THISDIR)/Advanced_wyy.asp /www/Advanced_wyy.asp
	$(ROMFSINST) $(THISDIR)/unblockmusic.tar.gz /etc_ro/unblockmusic.tar.gz
ifeq ($(CONFIG_FIRMWARE_INCLUDE_WYYBIN),y)
	$(ROMFSINST) -p +x $(THISDIR)/UnblockNeteaseMusic /usr/bin/UnblockNeteaseMusic
endif

