#!/bin/sh
# Compile:by-lanse    2020-06-15

STORAGE_HOME="/etc/storage/adbyby"
TMP_ABD=/tmp/tmp_abd
ABD=/etc/storage/dnsmasq.ad/dnsmasq.adblock

[ -f $ABD ] && rm -rf $ABD;[ -f $TMP_ABD ] && rm -rf $TMP_ABD

wget -t 5 -T 10 -c --no-check-certificate -O- "https://easylist-downloads.adblockplus.org/easylistchina.txt" \
|grep ^\|\|[^\*]*\^$ |sed -e 's:||:address\=\/:' -e 's:\^:/0\.0\.0\.0:' > $TMP_ABD

sleep 2
mv -f $TMP_ABD $ABD && chmod 644 $ABD
restart_dhcpd && sleep 3
