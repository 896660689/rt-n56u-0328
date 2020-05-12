#!/bin/sh
# Compile:by-lanse	2020-05-12

ss_proc="/var/ss-redir"
ss_bin="ss-redir"
ss_json_file="/tmp/ss-redir.json"
Storage="/etc/storage"
Firewall_rules="/etc/storage/post_iptables_script.sh"
Dnsmasq_dns="/etc/storage/dnsmasq/dnsmasq.conf"
Dnsmasq_d_dns="/etc/storage/dnsmasq.d/dns"
Dns_ipv6=$(nvram get ip6_service)
username=$(nvram get http_username)
route_vlan=$(nvram get lan_ipaddr)

ss_type=$(nvram get ss_type)		#0=ss;1=ssr
ss_local_port=$(nvram get ss_local_port)
ss_udp=$(nvram get ss_udp)
ss_server=$(nvram get ss_server)
ss_watchcat=$(nvram get ss_watchcat)
ss_dns=$(nvram get ss_dns)
ss_server_port=$(nvram get ss_server_port)
ss_method=$(nvram get ss_method)
ss_password=$(nvram get ss_key)
ss_mtu=$(nvram get ss_mtu)
ss_timeout=$(nvram get ss_timeout)
ss_mode=$(nvram get ss_mode)		#0:Agente-Global;1:chnroute;2:gfwlist
ss_router_proxy=$(nvram get ss_router_proxy)
ss_lower_port_only=$(nvram get ss_lower_port_only)
ss_tunnel_local_port=$(nvram get ss-tunnel_local_port)
ss_tunnel_remote=$(nvram get ss-tunnel_remote)

if [ "${ss_type:-0}" = "0" ] ; then
	ln -sf /usr/bin/ss-orig-redir $ss_proc
elif [ "${ss_type:-0}" = "1" ] ; then
	ss_protocol=$(nvram get ss_protocol)
	ss_proto_param=$(nvram get ss_proto_param)
	ss_obfs=$(nvram get ss_obfs)
	ss_obfs_param=$(nvram get ss_obfs_param)
	ln -sf /usr/bin/ssr-redir $ss_proc
fi

loger() {
	logger -st "$1" "$2"
}

get_arg_udp() {
	if [ "$ss_udp" = "1" ]
	then
		echo "-u"
	fi
}

get_arg_out(){
	if [ "$ss_router_proxy" = "1" ]
	then
		echo "-o"
	fi
}

get_wan_bp_list(){
	wanip="$(nvram get wan_ipaddr)"
	[ -n "$wanip" ] && [ "$wanip" != "0.0.0.0" ] && bp="-b $wanip" || bp=""
	if [ "$ss_mode" = "1" ]
	then
		bp=${bp}" -B /etc/storage/chinadns/chnroute.txt"
	fi
	echo "$bp"
}

get_ipt_ext(){
	if [ "$ss_lower_port_only" = "1" ]
	then
		echo '-e "--dport 22:1023"'
	elif [ "$ss_lower_port_only" = "2" ]
	then
		echo '-e "-m multiport --dports 53,80,443"'
	fi
}

func_start_ss_redir(){
	grep "gfwlist" $Firewall_rules
	if [ "$?" -eq "0" ]
	then
		sed -i '/gfwlist/d' $Firewall_rules
	fi
	killall -q pdnsd
	sh -c "$ss_bin -c $ss_json_file $(get_arg_udp) & "
	return $?
}

func_start_ss_rules(){
	ss-rules -f
	sh -c "ss-rules -s $ss_server -l $ss_local_port $(get_wan_bp_list) -d SS_SPEC_WAN_AC $(get_ipt_ext) $(get_arg_out) $(get_arg_udp)"
	return $?
}

func_ss_Close(){
	if [ -f /var/run/pdnsd.pid ]
	then
		kill $(cat /var/run/pdnsd.pid) >/dev/null 2>&1
	else
		kill -9 $(busybox ps -w | grep pdnsd | grep -v grep | awk '{print $1}') >/dev/null 2>&1
	fi
	if [ -f /var/run/gfwlist.pid ]
	then
		kill -9 $(busybox ps -w | grep gfwlist | grep -v grep | awk '{print $1}') >/dev/null 2>&1
	fi
	killall -q pdnsd; killall -q dns-forwarder; killall -q dnsproxy
	killall -q $ss_bin; killall -q ss-watchcat
	grep "conf-dir" $Dnsmasq_dns
	if [ "$?" -eq "0" ]
	then
		sed -i '/listen-address/d; /min-cache/d; /conf-dir/d; /log/d' $Dnsmasq_dns
		restart_dhcpd && sleep 2
	fi
	if [ -f /tmp/gfw-ipset.txt ]
	then
		awk '!/^$/&&!/^#/{printf("del gfwlist %s'" "'\n",$0)}' /tmp/gfw-ipset.txt > /tmp/ss-gfwlist.ipset >/dev/null 2>&1
		ipset restore -f /tmp/ss-gfwlist.ipset
		rm -f /tmp/ss-gfwlist.ipset
	fi
	grep "gfwlist" $Firewall_rules
	if [ "$?" -eq "0" ]
	then
		sed -i '/gfwlist/d' $Firewall_rules
		iptables -t nat -D PREROUTING -i br0 -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port $ss_local_port
		iptables -t nat -D OUTPUT -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port $ss_local_port
		restart_firewall && sleep 2
	fi
}

func_gfwlist_list(){
	if [ ! -f "/etc/storage/ss_dom.sh" ] || [ ! -s "/etc/storage/ss_dom.sh" ]
	then
		cat > "/etc/storage/ss_dom.sh" <<EOF
### 强制走 [ gfwlist ] 代理模式的域名黑名单
### 只填入网址名称或关键字即可,如下:
bitbucket.org
youtube.com
youneed.win
livestream.com
githubusercontent.com
gnews.org
gtv.org
gtv1.org
suannai.me
travis-ci.com
transfer.sh

EOF
		chmod 644 /etc/storage/ss_dom.sh
	fi
	if [ ! -f "/etc/storage/ss_pc.sh" ] || [ ! -s "/etc/storage/ss_pc.sh" ]
	then
		cat > "/etc/storage/ss_pc.sh" <<EOF
### 排除走 [ gfwlist ] 代理模式的域名白名单
### 只填入网址名称或关键字即可,如下:
speedtest.cn

EOF
		chmod 644 /etc/storage/ss_pc.sh
	fi
}

func_gen_ss_json(){
cat > "$ss_json_file" <<EOF
{
	"server": "$ss_server",
	"server_port": $ss_server_port,
	"password": "$ss_password",
	"method": "$ss_method",
	"timeout": $ss_timeout,
	"protocol": "$ss_protocol",
	"protocol_param": "$ss_proto_param",
	"obfs": "$ss_obfs",
	"obfs_param": "$ss_obfs_param",
	"local_address": "0.0.0.0",
	"local_port": $ss_local_port,
	"mtu": $ss_mtu
}
EOF
}

func_ss_pdnsd(){
	Config_Pdnsd="/var/pdnsd/pdnsd.conf"
	if [ -f "/usr/bin/pdnsd" ]
	then
		logger -t "[ShadowsocksR]" "加载 [pdnsd] 运行文件..."
		tcp_dns_list="1.1.1.1, 208.67.222.222, 208.67.220.220"
		if [ ! -d /var/pdnsd ]
		then
			mkdir -p -m 755 /var/pdnsd
			echo -ne "pd13\000\000\000\000" >/var/pdnsd/pdnsd.cache
			chown -R nobody:nogroup /var/pdnsd
		fi
		export PATH=$PATH:/var/pdnsd
		export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/lib:/var/pdnsd
		if [ ! -f $Config_Pdnsd ]
		then
			cat > $Config_Pdnsd <<EOF
global {
	perm_cache = 968;
	cache_dir = "/var/pdnsd";
	pid_file = "/var/run/pdnsd.pid";
	run_as = "$username";
	server_ip = 127.0.0.1;
	server_port = $ss_tunnel_local_port;
	status_ctl = on;
	query_method = tcp_only;
	min_ttl = 1h;
	max_ttl = 1w;
	timeout = 10;
	neg_domain_pol = on;
}

server {
	label = "Ch DNS";    // 解析其它server以外域
	ip = 223.5.5.5, 182.254.116.116;
	timeout = 4;
	uptest = none;
	interval = 15m;
	purge_cache = off;
	policy = included;   // 排除以下指定域
	exclude = ".gmail.com",
		".google-analytics.com",
		".google.cn",
		".google.com";
}
/*
server {
	label = "Google DNS";    // 只解析指定域
	ip = 8.8.4.4, 8.8.8.8;
	timeout = 5;
	uptest = none;
	edns_query = on;
	policy = excluded;    // 解析以下指定域
	include = ".gmail.com",
		".google-analytics.com",
		".google.cn",
		".google.com";
}
*/
server {
	label = "Open DNS";
	ip = $tcp_dns_list;
	reject_policy = fail;    // 以下污染源跳过
	reject = 208.69.32.0/24,
		208.69.34.0/24,
		208.67.219.0/24;
	port = 5353;
	timeout = 5;
	uptest = none;
	interval = 10m;
	purge_cache = off;    // 以下排除国外DNS解析
	exclude = ".cn",
		".qq.com",
		".alipay.com";
		".baidu.com";	
		".kuaishou.com";}

source {
	owner = $route_vlan;
	file = "/etc/hosts";
}

rr {
	name = $route_vlan;
	reverse = on;
	a = 127.0.0.1;
	owner = $route_vlan;
	soa = $route_vlan,$username.$route_vlan,42,86400,900,86400,86400;
}

EOF
			chmod 644 $Config_Pdnsd
		fi
		if [ ! -f "/var/pdnsd/pdnsd" ]; then
			ln -sf /usr/bin/pdnsd /var/pdnsd/pdnsd
		fi
		/var/pdnsd/pdnsd -c $Config_Pdnsd -d
	fi
}

func_gfwlist_import(){
	if [ -s "$Storage/ss_dom.sh" ]
	then
		sleep 2 && logger -t "[gfwlist]" "添加强制域名黑名单..."
		cat $Storage/ss_dom.sh | grep -v '^#' | grep -v "^$" > /tmp/ss_dom.txt
		awk '{printf("server=/%s/127.0.0.1#5353\nipset=/%s/gfwlist\n", $1, $1 )}' /tmp/ss_dom.txt > $Storage/gfwlist/gfwlist_black.conf
		chmod 644 $Storage/gfwlist/gfwlist_black.conf
	fi
	if [ -s "$Storage/ss_pc.sh" ]
	then
		sed -i '/127.0.0.1/d' $Storage/dnsmasq/dnsmasq.servers
		cat $Storage/ss_pc.sh | grep -v '^#' | grep -v "^$" > /tmp/ss_pc.txt
		awk '{printf("server=/%s/127.0.0.1\n", $1, $1 )}' /tmp/ss_pc.txt >> $Storage/dnsmasq/dnsmasq.servers
	fi
	rm -f /tmp/ss_dom.txt /tmp/ss_pc.txt
}

func_port_agent_mode(){
	if [ "$ss_router_proxy" = "1" ]
	then
		killall -q pdnsd; killall -q dns-forwarder; killall -q dnsproxy
		logger "Local agent"
	elif [ "$ss_router_proxy" = "2" ]
	then
		/usr/bin/dns-forwarder -b 127.0.0.1 -p $ss_tunnel_local_port -s $ss_tunnel_remote >/dev/null 2>&1 &
		logger -t "[DNS]" "使用 [dns-forwarder] 代理模式解析..."
	elif [ "$ss_router_proxy" = "3" ]
	then
		/usr/bin/dnsproxy -T -p $ss_tunnel_local_port -R 8.8.4.4 >/dev/null 2>&1 &
		logger -t "[DNS]" "使用 [dnsproxy] 代理模式解析..."
	elif [ "$ss_router_proxy" = "4" ]
	then
		func_ss_pdnsd && \
		logger -t "[DNS]" "使用 [pdnsd] 代理模式解析..."
	else
		logger -t "[DNS]" "未使用代理模式..."
	fi
}

func_ss_gfw(){
	[ -f /tmp/tmp_dnsmasq ] && rm /tmp/tmp_dnsmasq
	if [ -f "/etc/storage/dnsmasq/dnsmasq.conf" ]
	then
		grep "gfwlist" /etc/storage/dnsmasq/dnsmasq.conf
		if [ ! "$?" -eq "0" ]
		then
			logger -t "[ShadowsocksR]" "添加 [gfwlist] 启动路径 ..."
			sed -i '/listen-address/d; /min-cache/d; /conf-dir/d; /log/d' /etc/storage/dnsmasq/dnsmasq.conf
			echo "listen-address=${route_vlan},127.0.0.1
# 开启日志选项
log-queries
log-facility=/var/log/ss-watchcat.log
# 异步log,缓解阻塞，提高性能。默认为5，最大为100
log-async=48
# 缓存最长时间
min-cache-ttl=3600
# 指定服务器'域名''地址'文件夹
conf-dir=/etc/storage/gfwlist/" >> /tmp/tmp_dnsmasq.conf
			cat /tmp/tmp_dnsmasq.conf | sed -E -e "/#/d" >> /etc/storage/dnsmasq/dnsmasq.conf
			rm /tmp/tmp_dnsmasq.conf
		fi
	fi
	restart_dhcpd && sleep 3
}

func_ss_ipset(){
	logger -t "[ShadowsocksR]" "创建 [gfwlist] [ipset] 列表!"
	if [ ! -f "/tmp/gfw-ipset.txt" ]
	then
		echo "1.1.1.1
208.67.222.222
91.108.12.0/22
91.108.4.0/22
91.108.8.0/22
91.108.16.0/22
91.108.56.0/22
149.154.160.0/20
149.154.164.0/22
149.154.172.0/22
204.246.176.0/20
149.154.172.0/22" > /tmp/gfw-ipset.txt
		echo "create gfwlist hash:net family inet hashsize 1024 maxelem 65536" > /tmp/ss-gfwlist.ipset
		awk '!/^$/&&!/^#/{printf("add gfwlist %s'" "'\n",$0)}' /tmp/gfw-ipset.txt >> /tmp/ss-gfwlist.ipset >/dev/null 2>&1
		ipset flush gfwlist
		ipset -! restore < /tmp/ss-gfwlist.ipset 2>/dev/null
	fi
	rm -f /tmp/ss-gfwlist.ipset /tmp/gfw-ipset.txt
}

func_ss_firewall(){
	grep "gfwlist" $Firewall_rules
	if [ ! "$?" -eq "0" ]
	then
		sed -i '/^\s*$/d; /gfwlist/d' $Firewall_rules
		cat >> $Firewall_rules <<EOF

iptables -t nat -I PREROUTING -i br0 -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port $ss_local_port
iptables -t nat -I OUTPUT -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port $ss_local_port

EOF
	fi
	## iptables -t nat -I PREROUTING -p tcp -m set --match-set gfwlist dst -j REDIRECT --to-port $ss_local_port
	restart_firewall && sleep 2
	logger -t "[ShadowsocksR]" "开始运行"
}

func_ss_dns(){
	if [ "$ss_dns" = "1" ] ; then
		if [ ! -d "$Dnsmasq_d_dns" ]
		then
			mkdir -p -m 755 $Dnsmasq_d_dns
			cp -f /etc/resolv.conf $Dnsmasq_d_dns/resolv_bak
		fi
		if [ ! -f "$Dnsmasq_d_dns/resolv.conf" ]
		then
			cat > $Dnsmasq_d_dns/resolv.conf <<EOF
127.0.0.1
223.5.5.5
182.254.116.116
208.67.222.222
114.114.114.114
2001:da8::666
240c::6666
EOF
			chmod 644 $Dnsmasq_d_dns/resolv.conf && chmod 644 /etc/resolv.conf
		fi
		grep "208.67" /etc/resolv.conf
		if [ ! "$?" -eq "0" ]
		then
			awk '!/^$/&&!/^#/{printf("nameserver %s'" "'\n",$0)}' $Dnsmasq_d_dns/resolv.conf >> /tmp/resolv.conf
			if [ "$Dns_ipv6" = "" ]
			then
				sed -i '/2001/d; /240c/d' /tmp/resolv.conf
			fi
			mv -f /tmp/resolv.conf /etc/resolv.conf
		fi
	else
		if [ -f "$Dnsmasq_d_dns/resolv_bak" ]
		then
			cp -rf $Dnsmasq_d_dns/resolv_bak /etc/resolv.conf
		else
			sed -i '/208.67/d; /223.5.5.5/d; /182.254/d; /2001/d; /240c/d' /etc/resolv.conf
		fi
	fi
}

func_ss_watchcat(){
	if [ "$ss_watchcat" = "1" ]
	then
		if [ ! -n "$(pidof ss-watchcat)" ]
		then
			/usr/bin/ss-watchcat >/dev/null 2>&1 &
			logger "Watchdog start up"
		fi
	else
		if [ -n "$(pidof ss-watchcat)" ]
		then
			kill -9 "$(pidof ss-watchcat)"
		fi
	fi
}

func_start(){
	func_gfwlist_list && \
	func_gen_ss_json && \
	func_port_agent_mode && \
	if [ "$ss_mode" = "2" ]
	then
		func_gfwlist_import && \
		func_ss_gfw && \
		func_ss_ipset && \
		func_ss_firewall && \
		$ss_bin -c $ss_json_file -b 0.0.0.0 -l $ss_local_port >/dev/null 2>&1 &
		logger -t "[ShadowsocksR]" "使用 [gfwlist] 代理模式开始运行..."
	else
		func_start_ss_redir && \
		func_start_ss_rules && \
		loger $ss_bin "ShadowsocksR Start up" || { ss-rules -f && loger $ss_bin "ShadowsocksR Start fail!";}
	fi
	func_ss_dns && \
	func_ss_watchcat && \
	echo -e "\e[1;42m ShadowsocksR 启动完成\e[0m"
}

func_stop(){
	nvram set ss-tunnel_enable=0
	/usr/bin/ss-tunnel.sh stop
	ss-rules -f; loger $ss_bin "stop"
	func_ss_dns && \
	func_ss_Close && \
	[ -f /tmp/ss-redir.json ] && rm -f /tmp/ss-redir.json
	[ -f /var/run/ss-watchdog.pid ] && rm -rf /var/run/ss-watchdog.pid
	[ -f /var/log/ss-watchcat.log ] && rm -f /var/log/ss-watchcat.log
	[ -f /var/run/pdnsd.pid ] && rm -rf /var/run/pdnsd.pid
	[ -f /tmp/shadowsocks_iptables.save ] && rm -f /tmp/shadowsocks_iptables.save
	[ -d /var/pdnsd ] && rm -rf /var/pdnsd
	[ -f /tmp/gfw-ipset.txt ] && rm -f /tmp/gfw-ipset.txt
	[ -f $Dnsmasq_d_dns/resolv_bak ] && cp -rf $Dnsmasq_d_dns/resolv_bak /etc/resolv.conf
	[ -d $Dnsmasq_d_dns ] && rm -rf $Dnsmasq_d_dns
	logger -t "[ShadowsocksR]" "已停止运行!"
}

case "$1" in
start)
	func_start
	;;
stop)
	func_stop
	;;
restart)
	func_stop
	func_start
	;;
*)
	echo "Usage: $0 { start | stop | restart }"
	exit 1
	;;
esac

