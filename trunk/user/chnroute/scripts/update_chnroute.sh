#!/bin/sh
# Compile:by-lanse	2019-12-12

tmp_chnroute="/tmp/chnroute.txt"
set -e -o pipefail

[ -f $tmp_chnroute ] && rm -rf $tmp_chnroute && logger -st "chnroute" "Starting update..."

if [ "$1" != "force" ] && [ "$(nvram get ss_update_chnroute)" != "1" ]; then
	exit 0
else
	[ ! -d "/etc/storage/chinadns" ] && mkdir -p /etc/storage/chinadns
	wget -t 15 -T 50 -c --no-check-certificate -O- "https://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest" \
	|awk -F\| '/CN\|ipv4/ { printf("%s/%d\n", $4, 32-log($5)/log(2)) }' >> $tmp_chnroute

	if [ -s "$tmp_chnroute" ] ; then
		touch /tmp/chnroute-md5.json && md5sum /etc/storage/chinadns/chnroute.txt > /tmp/chnroute-md5.json
		touch /tmp/chinadns-md5.json && md5sum $tmp_chnroute > /tmp/chinadns-md5.json
		chnroute_local=$(grep 'chnroute' /tmp/chnroute-md5.json | awk -F' ' '{print $1}')
		chinadns_md5=$(grep 'ch' /tmp/chinadns-md5.json | awk -F' ' '{print $1}')
		if [ "$chnroute_local"x == "$chinadns_md5"x ] ; then
			logger -t "chnroute" "No update"
			rm -f $tmp_chnroute
		else
			chmod 644 $tmp_chnroute && mv -f $tmp_chnroute /etc/storage/chinadns/chnroute.txt; sleep 2
			[ -f /usr/bin/shadowsocks.sh ] && [ "$(nvram get ss_enable)" = "1" ] && /usr/bin/shadowsocks.sh restart >/dev/null 2>&1
			logger -t "chnroute" "update rule"
		fi
		rm -f /tmp/chnroute-md5.json /tmp/chinadns-md5.json
	fi
fi

