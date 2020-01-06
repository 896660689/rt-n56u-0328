THISDIR = $(shell pwd)
all:

clean:

romfs:
	$(ROMFSINST) /etc_ro/adbyby.tar.gz
	$(ROMFSINST) $(THISDIR)/scripts/ /usr/bin/
	$(ROMFSINST) $(THISDIR)/Advanced_adbyby.asp /www/Advanced_adbyby.asp
	$(ROMFSINST) $(THISDIR)/Ad_action.asp /www/Ad_action.asp
