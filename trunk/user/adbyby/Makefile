THISDIR = $(shell pwd)

AD_HOME=adbyby

all: adbyby_dl

adbyby_dl:
ifeq ($(CONFIG_FIRMWARE_INCLUDE_ADBYBY),y)
	( if [ -d $(AD_HOME) ]; then \
		tar zcf adbyby.tar.gz $(AD_HOME) ; \
	fi )
endif

clean:

romfs:
	chmod -R +x ./adbyby
	$(ROMFSINST) $(THISDIR)/adbyby.tar.gz /etc_ro/adbyby.tar.gz
	$(ROMFSINST) -p +x $(THISDIR)/adbyby.sh /usr/bin/adbyby.sh
	$(ROMFSINST) $(THISDIR)/Advanced_adbyby.asp /www/Advanced_adbyby.asp
	$(ROMFSINST) $(THISDIR)/Ad_action.asp /www/Ad_action.asp

