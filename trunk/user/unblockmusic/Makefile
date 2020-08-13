THISDIR := $(shell pwd)
export GO111MODULE=on
export GOPROXY=https://goproxy.io
UM_VERSION := 0.2.4
UM_URL := https://github.com/cnsilvan/UnblockNeteaseMusic/archive/$(UM_VERSION).tar.gz

all: unblockmusic_dl

unblockmusic_dl:
	( if [ -d unblockmusic ]; then \
		tar zcf unblockmusic.tar.gz unblockmusic ; \
	fi )

build_extract:
	mkdir -p $(THISDIR)/UnblockNeteaseMusicGo
	mkdir -p $(THISDIR)/bin
	( if [ ! -d $(THISDIR)/UnblockNeteaseMusicGo/UnblockNeteaseMusic-$(UM_VERSION) ]; then \
	tar zxfv $(THISDIR)/UnblockNeteaseMusic-$(UM_VERSION).tar.gz -C $(THISDIR)/UnblockNeteaseMusicGo ; \
	fi )

build:
	( cd $(THISDIR)/UnblockNeteaseMusicGo/UnblockNeteaseMusic-$(UM_VERSION); \
	GOOS=linux GOARCH=mipsle go build -ldflags "-w -s" -o $(THISDIR)/bin/UnblockNeteaseMusic; \
	) 

download_um:
	( if [ ! -f $(THISDIR)/UnblockNeteaseMusic-$(UM_VERSION).tar.gz ]; then \
	curl --create-dirs -L $(UM_URL) -o $(THISDIR)/UnblockNeteaseMusic-$(UM_VERSION).tar.gz ; \
	fi )

clean:
	rm -rf $(THISDIR)/UnblockNeteaseMusicGo
	rm -rf $(THISDIR)/bin

romfs:
	chmod -R +x ./unblockmusic
	$(ROMFSINST) -p +x $(THISDIR)/unblockmusic.sh /usr/bin/unblockmusic.sh
	$(ROMFSINST) $(THISDIR)/Advanced_wyy.asp /www/Advanced_wyy.asp
	$(ROMFSINST) $(THISDIR)/unblockmusic.tar.gz /etc_ro/unblockmusic.tar.gz
ifeq ($(CONFIG_FIRMWARE_INCLUDE_WYYBIN),y)
	$(ROMFSINST) -p +x $(THISDIR)/UnblockNeteaseMusic /usr/bin/UnblockNeteaseMusic
endif

