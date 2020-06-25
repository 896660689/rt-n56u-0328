#!/bin/sh

change_dns() {
	if [ "$(nvram get adg_redirect)" = 1 ] ; then
		sed -i '/no-resolv/d' /etc/storage/dnsmasq/dnsmasq.conf
		sed -i '/server=127.0.0.1/d' /etc/storage/dnsmasq/dnsmasq.conf
		cat >> /etc/storage/dnsmasq/dnsmasq.conf << EOF
no-resolv
server=127.0.0.1#5335
EOF
		sleep 2 && restart_dhcpd &
		logger -t "AdGuardHome" "添加DNS转发到5335端口"
	fi
}

del_dns() {
	sed -i '/no-resolv/d' /etc/storage/dnsmasq/dnsmasq.conf
	sed -i '/server=127.0.0.1#5335/d' /etc/storage/dnsmasq/dnsmasq.conf
	sleep 2 && restart_dhcpd &
}

set_iptable() {
    if [ "$(nvram get adg_redirect)" = 2 ] ; then
		IPS="`ifconfig |grep "inet addr" |grep -v ":127" |grep "Bcast" |awk '{print $2}' |awk -F : '{print $2}'`"
		for IP in $IPS
		do
			iptables -t nat -A PREROUTING -p tcp -d "$IP" --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
			iptables -t nat -A PREROUTING -p udp -d "$IP" --dport 53 -j REDIRECT --to-ports 5335>/dev/null 2>&1
		done

		IPS="`ifconfig |grep "inet6 addr" |grep -v " fe80::" |grep -v " ::1" |grep "Global" |awk '{print $3}'`"
		for IP in $IPS
		do
			ip6tables -t nat -A PREROUTING -p tcp -d "$IP" --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
			ip6tables -t nat -A PREROUTING -p udp -d "$IP" --dport 53 -j REDIRECT --to-ports 5335 >/dev/null 2>&1
		done
		logger -t "AdGuardHome" "重定向53端口"
    fi
}

clear_iptable() {
	OLD_PORT="5335"
	IPS="`ifconfig |grep "inet addr" |grep -v ":127" |grep "Bcast" |awk '{print $2}' |awk -F : '{print $2}'`"
	for IP in $IPS
	do
		iptables -t nat -D PREROUTING -p udp -d "$IP" --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
		iptables -t nat -D PREROUTING -p tcp -d "$IP" --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
	done

	IPS="`ifconfig |grep "inet6 addr" |grep -v " fe80::" |grep -v " ::1" |grep "Global" |awk '{print $3}'`"
	for IP in $IPS
	do
		ip6tables -t nat -D PREROUTING -p udp -d "$IP" --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
		ip6tables -t nat -D PREROUTING -p tcp -d "$IP" --dport 53 -j REDIRECT --to-ports $OLD_PORT >/dev/null 2>&1
	done
}

getconfig(){
	adg_file="/etc/storage/AdGuardHome/adg.rules"
	if [ ! -f "$adg_file" ] || [ ! -s "$adg_file" ] ; then
		cat > "$adg_file" <<-\EEE
bind_host: 0.0.0.0
bind_port: 3030
users:
- name: admin
  password: $2a$10$cXxR/BU7DZEtKMc/bM/G5u05Z3xap6T4dqXrx8UFRYP1V9e3W3.3W
language: zh-cn
rlimit_nofile: 0
web_session_ttl: 720
dns:
  bind_host: 0.0.0.0
  port: 5335
  statistics_interval: 1
  querylog_enabled: true
  querylog_interval: 90
  querylog_memsize: 0
  protection_enabled: true
  blocking_mode: nxdomain
  blocking_ipv4: ""
  blocking_ipv6: ""
  blocked_response_ttl: 50
  ratelimit: 0
  ratelimit_whitelist: []
  refuse_any: true
  bootstrap_dns:
  - 119.29.29.29
  - 223.5.5.5
  - 114.114.114.114
  all_servers: true
  edns_client_subnet: false
  aaaa_disabled: true
  allowed_clients: []
  disallowed_clients: []
  blocked_hosts: []
  parental_block_host: family-block.dns.adguard.com
  safebrowsing_block_host: standard-block.dns.adguard.com
  cache_size: 4194304
  upstream_dns:
  - 127.0.0.1:6053
  filtering_enabled: true
  filters_update_interval: 24
  parental_enabled: false
  safesearch_enabled: false
  safebrowsing_enabled: false
  safebrowsing_cache_size: 1048576
  safesearch_cache_size: 1048576
  parental_cache_size: 1048576
  cache_time: 30
  rewrites: []
  blocked_services: []
tls:
  enabled: false
  server_name: ""
  force_https: false
  port_https: 443
  port_dns_over_tls: 853
  allow_unencrypted_doh: false
  strict_sni_check: false
  certificate_chain: ""
  private_key: ""
  certificate_path: ""
  private_key_path: ""
filters:
- enabled: false
  url: https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt
  name: AdGuard Simplified Domain Names filter
  id: 1
- enabled: false
  url: https://adaway.org/hosts.txt
  name: AdAway
  id: 2
- enabled: false
  url: https://hosts-file.net/ad_servers.txt
  name: hpHosts - Ad and Tracking servers only
  id: 3
- enabled: false
  url: https://www.malwaredomainlist.com/hostslist/hosts.txt
  name: MalwareDomainList.com Hosts List
  id: 4
- enabled: true
  url: https://gitee.com/xinggsf/Adblock-Rule/raw/master/mv.txt
  name: 乘风 视频
  id: 5
- enabled: true
  url: My AdFilters，https://gitee.com/halflife/list/raw/master/ad.txt
  name: My AdFilters
  id: 6
- enabled: true
  url: https://gitee.com/privacy-protection-tools/anti-ad/raw/master/easylist.txt
  name: anti-AD
  id: 7
- enabled: false
  url: https://cdn.jsdelivr.net/gh/neoFelhz/neohosts@gh-pages/basic/hosts.txt
  name: neoHosts Basic
  id: 9
- enabled: false
  url: https://cdn.jsdelivr.net/gh/neoFelhz/neohosts@gh-pages/full/hosts.txt
  name: neoHosts Full
  id: 10
- enabled: false
  url: https://gitlab.com/CHEF-KOCH/cks-filterlist/raw/master/hosts/Ads-tracker.txt
  name: CHEF-KOCH ADs
  id: 11
- enabled: false
  url: https://zerodot1.gitlab.io/CoinBlockerLists/hosts
  name: CoinBlocker
  id: 12
whitelist_filters: []
user_rules:
- '@@mps.ts'
dhcp:
  enabled: false
  interface_name: ""
  gateway_ip: ""
  subnet_mask: ""
  range_start: ""
  range_end: ""
  lease_duration: 86400
  icmp_timeout_msec: 1000
clients: []
log_file: ""
verbose: false
schema_version: 6

EEE
		chmod 755 "$adg_file"
	fi
}

dl_adg(){
	logger -t "AdGuardHome" "下载AdGuardHome"
	#wget -t 5 -T 10 -c --no-check-certificate -O- "https://github.com/AdguardTeam/AdGuardHome/releases/download/v0.102.0/AdGuardHome_linux_mipsle.tar.gz" > /tmp/AdGuardHome.tar.gz
	curl -k -s -o /tmp/AdGuardHome/AdGuardHome --connect-timeout 10 --retry 3 https://cdn.jsdelivr.net/gh/chongshengB/rt-n56u/trunk/user/adguardhome/AdGuardHome
	sleep 2
	if [ ! -f "/tmp/AdGuardHome/AdGuardHome" ] ; then
		logger -t "AdGuardHome" "AdGuardHome下载失败，请检查是否能正常访问github!程序将退出。"
		nvram set adg_enable=0
		exit 0
	else
		chmod 777 /tmp/AdGuardHome/AdGuardHome && \
		logger -t "AdGuardHome" "AdGuardHome下载成功。"
	fi
}

start_adg(){
	mkdir -p /tmp/AdGuardHome
	mkdir -p /etc/storage/AdGuardHome
	if [ ! -f "/tmp/AdGuardHome/AdGuardHome" ] ; then
		dl_adg
	fi
	getconfig && \
	change_dns && \
	set_iptable && \
	logger -t "AdGuardHome" "运行AdGuardHome"
	eval "/tmp/AdGuardHome/AdGuardHome -c $adg_file -w /tmp/AdGuardHome -v" &
}
stop_adg(){
	rm -rf /tmp/AdGuardHome
	#[ -d "/etc/storage/AdGuardHome" ] && rm -rf "/etc/storage/AdGuardHome"
	killall -9 AdGuardHome
	del_dns && \
	clear_iptable &
}

case "$1" in
start)
	start_adg
	;;
stop)
	stop_adg
	;;
*)
	echo "check"
	;;
esac

