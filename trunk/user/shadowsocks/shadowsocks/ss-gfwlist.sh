#!/bin/sh
# Compile:by-lanse	2020-06-28

modprobe xt_set
modprobe ip_set_hash_ip
modprobe ip_set_hash_net

usage() {
	cat <<-EOF
		Usage: ss-gfwlist [options]

		Valid options are:

			-s <server_ips>         ip address of shadowsocks remote server
			-O                      apply the global rules to the OUTPUT chain
			-f                      flush the rules
			-g                      gfwlist mode
			-h                      show this help message and exit
EOF
	exit "$1"
}

loger() {
    # 1.alert 2.crit 3.err 4.warn 5.notice 6.info 7.debug
    logger -st /usr/bin/ss-gfwlist[$$] -p"$1" "$2"
}

ROUTE_VLAN=$(nvram get lan_ipaddr)
DNSMASQ_RURE="/etc/storage/dnsmasq/dnsmasq.conf"
DNSMASQ_TMP="/tmp/tmp_dnsmasq.conf"

SS_LOCAL_PORT_LINK=$(nvram get ss_local_port)
SS_SERVER_LINK=$(nvram get ss_server)

flush_path() {
	if grep -q "gfwlist" "$DNSMASQ_RURE"
	then
		echo 'Startup code exists'
	else
		logger -t "[Dnsmasq]" "添加 [gfwlist] 启动路径 ..."
		sed -i '/listen-address/d; /min-cache/d; /gfwlist/d; /log/d' $DNSMASQ_RURE && sleep 2
		echo -e "listen-address=$ROUTE_VLAN,127.0.0.1
# 开启日志选项
#log-queries
#log-facility=/var/log/ss-watchcat.log
# 异步log,缓解阻塞，提高性能。默认为5，最大为100
#log-async=50
# 缓存最长时间
min-cache-ttl=3600
# 指定服务器'域名''地址'文件夹
conf-dir=/etc/storage/gfwlist/" > $DNSMASQ_TMP
		cat $DNSMASQ_TMP | sed -E -e "/#/d" >> $DNSMASQ_RURE && sleep 2
		restart_dhcpd && sleep 2
		rm $DNSMASQ_TMP
	fi
}

flush_rules() {
	iptables-save -c | grep -v "gfwlist" | iptables-restore -c
	for setname in $(ipset -n list | grep "gfwlist"); do
		ipset destroy "$setname" 2>/dev/null
	done
	FWI="/tmp/shadowsocks_iptables.save"
	[ -n "$FWI" ] && echo '# firewall include file' >$FWI && \
	chmod +x $FWI
	return 0
}

ipset_init() {
    ipset -! restore <<-EOF || return 1
        create gfwlist hash:net hashsize 64
        $(gen_wa_fw_ip | sed -e "s/^/add gfwlist /")
EOF
    return 0
}

gen_wa_fw_ip() {
	cat <<-EOF | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}"
		216.58.200.238
		217.160.0.201
		172.217.160.78
		172.217.24.3
		172.217.160.110
		104.244.42.129
		104.18.9.230
		104.18.27.103
		67.228.126.62
		176.9.146.200
		46.4.7.165
		195.201.59.244
		136.243.22.80
		78.46.27.186
		85.10.210.166
		91.108.12.0/22
		91.108.4.0/22
		91.108.8.0/22
		91.108.16.0/22
		91.108.20.0/22
		91.108.36.0/23
		91.108.38.0/23
		91.108.56.0/22
		149.154.160.0/20
		149.154.164.0/22
		204.246.176.0/20
		149.154.172.0/22
EOF
}

ipt_nat() {
	include_ac_rules nat
	ipt="iptables -t nat"
	$ipt -A PREROUTING -i br0 -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port $SS_LOCAL_PORT_LINK || return 1
	$ipt -A OUTPUT -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port $SS_LOCAL_PORT_LINK
	return $?
}

include_ac_rules() {
	iptables-restore -n <<-EOF
	*$1
	:gfwlist - [0:0]
	-A gfwlist -d $SS_SERVER_LINK -j RETURN
	-A gfwlist -d 127.0.0.0/8 -j RETURN
	-A gfwlist -d 192.168.0.0/16 -j RETURN
	COMMIT
EOF
}

export_ipt_rules() {
	[ -n "$FWI" ] || return 0
	cat <<-CAT >>$FWI
	iptables-save -c | grep -v "gfwlist" | iptables-restore -c
	iptables-restore -n <<-EOF
	$(iptables-save | grep -E "gfwlist|^\*|^COMMIT" |\
		sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
	EOF
CAT
	return $?
}

while getopts ":s:O:g:f:h" arg; do
	case "$arg" in
		s)
			server=$(for ip in $OPTARG; do echo "$ip"; done)
			;;
		O)
			OUTPUT=gfwlist
			;;
		g)
			RUNMODE=gfwlist
			;;
		f)
			flush_rules
			exit 0
			;;
		h)
			usage 0
			;;
	esac
done

flush_path && flush_rules && ipset_init && ipt_nat && export_ipt_rules
[ "$?" = 0 ] || loger 3 "Start failed!"
exit $?

