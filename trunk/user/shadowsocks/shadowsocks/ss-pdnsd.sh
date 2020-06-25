#!/bin/sh
# Compile:by-lanse	2020-06-21

PDNSD_HOUSE="/var/pdnsd"
PDNSD_FILE="$PDNSD_HOUSE/pdnsd.conf"
PDNSD_CACHE="$PDNSD_HOUSE/pdnsd.cache"

USERNAME=$(nvram get http_username)
ROUTE_VLAN=$(nvram get lan_ipaddr)
SS_TUNNEL_LOCAL_PORT=$(nvram get ss-tunnel_local_port)
DNS_LIST="208.67.220.220,176.103.130.131,8.8.4.4"
CHN_LIST="119.29.29.29,223.5.5.5,114.114.114.114"

export PATH=$PATH:/var/pdnsd
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib:/var/pdnsd

if [ -f "/usr/bin/pdnsd" ] ; then
	if [ -n "$(pidof pdnsd)" ] ; then
		killall pdnsd >/dev/null 2>&1
	fi
	if [ ! -d "/var/pdnsd" ] ; then
		mkdir -p $PDNSD_HOUSE && chmod +X $PDNSD_HOUSE
		touch $PDNSD_CACHE
		chown -R nobody:nogroup /var/pdnsd
	fi
	[ -f "$PDNSD_FILE" ] && rm -rf $PDNSD_FILE
	cat > "$PDNSD_FILE" <<EOF
global {
    perm_cache = 936;
    cache_dir = "/var/pdnsd";
    pid_file = "/var/run/pdnsd.pid";
    run_as = "$USERNAME";
    server_ip = 127.0.0.1;
    server_port = $SS_TUNNEL_LOCAL_PORT;
    status_ctl = on;
    query_method = tcp_only;
    min_ttl = 1h;
    max_ttl = 1w;
    timeout = 10;
    neg_domain_pol = on;
}

server {
    label = "CN DNS";
    ip = $CHN_LIST;
    timeout = 4;
    uptest = none;
    interval = 10m;
    edns_query = on;
    purge_cache = off;
}

server {
    label = "Global DNS";
    ip = $DNS_LIST;
    reject_policy = fail;
    reject = 208.69.32.0/24,
         208.69.34.0/24,
         208.67.219.0/24;
    port = $SS_TUNNEL_LOCAL_PORT;
    timeout = 5;
    uptest = none;
    interval = 10m;
    purge_cache = off;
}

source {
    owner = $ROUTE_VLAN;
    file = "/etc/hosts";
}

rr {
    name = $ROUTE_VLAN;
    reverse = on;
    a = 127.0.0.1;
    owner = $ROUTE_VLAN;
    soa = $ROUTE_VLAN,$USERNAME.$ROUTE_VLAN,42,86400,900,86400,86400;
}
EOF
	chmod 644 $PDNSD_FILE
	if [ ! -f $PDNSD_HOUSE/pdnsd ] ; then
		ln -sf /usr/bin/pdnsd $PDNSD_HOUSE/pdnsd
	fi
	/var/pdnsd/pdnsd -c $PDNSD_FILE -d
	sleep 2 && logger "[ PDNSD ]" "Pdnsd Started..."
fi

