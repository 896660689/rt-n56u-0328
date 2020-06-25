#!/bin/sh -e
# Compile:by-lanse	2020-06-17

TMP_GFW="/tmp/gfwnew.txt"
TMP_RULE="/tmp/gfw_list.conf"
TMP_B64="/tmp/gfw.b64"
GFWLIST_HOME="/etc/storage/gfwlist"
GFWLIST_HOME_RULE="$GFWLIST_HOME/gfw_list.conf"
GFWLIST_URL="https://cdn.jsdelivr.net/gh/gfwlist/gfwlist/gfwlist.txt"
GFWLIST_B_URL="https://cokebar.github.io/gfwlist2dnsmasq/dnsmasq_gfwlist_ipset.conf"
ss_tunnel_local_port=$(nvram get ss-tunnel_local_port)

set -e -o pipefail
[ -f $TMP_GFW ] && rm -rf $TMP_GFW && logger -st "gfwlist" "Starting update..."

generate_china_banned()
{
	cat $1 | base64 -d > $TMP_RULE
		rm -f $1
    	sed -i '/^@@|/d' $TMP_RULE

	cat $TMP_RULE | sort -u |
		sed 's#!.\+##; s#|##g; s#@##g; s#http:\/\/##; s#https:\/\/##;' |
		sed '/\*/d; /apple\.com/d; /sina\.cn/d; /sina\.com\.cn/d; /baidu\.com/d; /byr\.cn/d; /jlike\.com/d; /weibo\.com/d; /zhongsou\.com/d; /youdao\.com/d; /sogou\.com/d; /so\.com/d; /soso\.com/d; /aliyun\.com/d; /taobao\.com/d; /jd\.com/d; /qq\.com/d' |
		sed '/^[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+$/d' |
		grep '^[0-9a-zA-Z\.-]\+$' | grep '\.' | sed 's#^\.\+##' | sort -u |
		awk '
BEGIN { prev = "________"; } {
	cur = $0;
	if (index(cur, prev) == 1 && substr(cur, 1 + length(prev) ,1) == ".") {
	} else {
		print cur;
		prev = cur;
	}
}' | sort -u

}

if [ "$1" != "force" ] && [ "$(nvram get ss_update_gfwlist)" != "1" ]; then
	exit 0
else
	[ ! -d "$GFWLIST_HOME" ] && mkdir -p $GFWLIST_HOME
	[ ! -f "$FWLIST_HOME_RULE" ] && touch $GFWLIST_HOME_RULE
	curl -k -s -o $TMP_B64 --connect-timeout 10 --retry 3 $GFWLIST_URL
	generate_china_banned $TMP_B64 \
	|sed -e "/.*/s/.*/server=\/&\/127.0.0.1#"$ss_tunnel_local_port"\nipset=\/&\/gfwlist/" > $TMP_GFW
	rm -f $TMP_RULE
	if [ -s "$TMP_GFW" ] ; then
		touch /tmp/gfwlist-md5.json && md5sum $GFWLIST_HOME_RULE > /tmp/gfwlist-md5.json
		touch /tmp/gfw-md5.json && md5sum $TMP_GFW > /tmp/gfw-md5.json
		gfwlist_local=$(grep 'gfwlist' /tmp/gfwlist-md5.json | awk -F' ' '{print $1}')
		gfwlist_md5=$(grep 'gfw' /tmp/gfw-md5.json | awk -F' ' '{print $1}')
		if [ "$gfwlist_local"x == "$gfwlist_md5"x ] ; then
			logger -t "gfwlist" "No update"
			rm -f $TMP_GFW
		else
			chmod 644 $TMP_GFW && mv -f $TMP_GFW $GFWLIST_HOME_RULE
			mtd_storage.sh save >/dev/null 2>&1
			killall -HUP dnsmasq && restart_dhcpd
			logger -t "gfwlist" "update rule"
		fi
		rm -f /tmp/gfwlist-md5.json /tmp/gfw-md5.json
	else
		wget -t 5 -T 10 -c --no-check-certificate -O- $GFWLIST_B_URL \
		|awk '!a[$0]++' |sed -e '/^#/d' > $TMP_GFW
		chmod 644 $TMP_GFW && mv -f $TMP_GFW $GFWLIST_HOME_RULE; sleep 2
		restart_dhcpd
		logger -t "gfwlist" "update rule"
	fi
fi

