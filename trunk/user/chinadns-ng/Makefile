SRC_NAME = chinadns-ng
SRC_URL=https://github.com/zfl9/chinadns-ng/archive/master.zip

THISDIR = $(shell pwd)

all: download_test extract_test
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME)/build

download_test:
	( if [ ! -f $(SRC_NAME).zip ]; then \
		wget -t5 --timeout=20 --no-check-certificate -O $(SRC_NAME).zip $(SRC_URL); \
		rm -f $(SRC_NAME) \
	fi )

extract_test:
	( if [ ! -d $(SRC_NAME) ]; then \
		unzip $(SRC_NAME).zip; \
	fi )


all: 
	$(MAKE) -j$(HOST_NCPU) -C $(SRC_NAME)

clean:
	if [ -f $(SRC_NAME)/Makefile ] ; then \
		$(MAKE) -C $(SRC_NAME) clean ; \
	fi ; \
	rm -f config_done

romfs:
	$(ROMFSINST) -p +x $(THISDIR)/$(SRC_NAME)/chinadns-ng /usr/bin/chinadns-ng
