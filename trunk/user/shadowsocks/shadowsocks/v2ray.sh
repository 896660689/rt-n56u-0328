#!/bin/sh
# Compile:by-lanse	2020-06-25

v2_json="/tmp/v2ray/config.json"
v2_home="/tmp/v2ray"
ss_mode=$(nvram get ss_mode)
STORAGE="/etc/storage"
SSR_HOME="$STORAGE/shadowsocks"
STORAGE_V2SH="$STORAGE/storage_v2ray.sh"
SS_LOCAL_PORT_LINK=$(nvram get ss_local_port)
ss_router_proxy=$(nvram get ss_router_proxy)
ss_tunnel_local_port=$(nvram get ss-tunnel_local_port)
SS_LAN_IP=$(nvram get lan_ipaddr)

func_download(){
	if [ ! -f "$v2_home/v2ray" ]
	then
		mkdir -p "$v2_home" && sleep 2
		curl -k -s -o $v2_home/v2ray --connect-timeout 10 --retry 3 https://cdn.jsdelivr.net/gh/896660689/OS/V2/v2ray_4.25.0 && \
		chmod 777 "$v2_home/v2ray"
	fi
	if [ "$ss_router_proxy" = "0" ]
	then
		/bin/bash $SSR_HOME/redsocks.sh start [ $1 ]
		/bin/bash $SSR_HOME/redsocks.sh iptables 107.167.18.43 && sleep 2
	fi
}

v2_server_file(){
	if [ ! -f "$STORAGE_V2SH" ] || [ ! -s "$STORAGE_V2SH" ]
	then
		cat > "$STORAGE_V2SH" <<EOF
{
  "inbounds":[
    {
      "port":$SS_LOCAL_PORT_LINK,
      "protocol":"socks",
      "settings":{
        "auth":"noauth",
        "udp":true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    },
    {
      "port":"1081",
      "protocol":"http",
      "settings":{},
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds":[
    {
      "protocol":"vmess",
      "settings":{
        "vnext":[
          {
            "address": "107.167.18.43",
            "port": 443,
            "users": [
              {
                "id": "418048af-a293-4b99-9b0c-98ca3580dd23",
                "alterId": 64,
                "security": "auto"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "allowInsecure": true,
          "serverName": "www.7921769.xyz"
        },
        "wsSettings": {
          "connectionReuse": true,
          "path": "/footers",
          "headers": {
            "Host": "www.7921769.xyz"
          }
        }
      }
    }
  ]
}
EOF
	chmod 644 "$STORAGE_V2SH"
	fi
}

func_Del_rule(){
	if [ -n "$(pidof v2ray)" ] ; then
		killall v2ray >/dev/null 2>&1 &
	fi
	sleep 2
	/bin/bash $SSR_HOME/redsocks.sh stop
}

func_v2_running(){
	if [ -s "$STORAGE_V2SH" ]
	then
		cp -f "$STORAGE_V2SH" "$v2_json"
	fi
	cd "$v2_home"
	./v2ray >/dev/null 2>&1 &
}

func_start(){
	if [ "$ss_mode" = "3" ]
	then
		func_Del_rule && \
		echo -e "\033[41;37m 部署 [v2ray] 文件,请稍后...\e[0m\n"
		v2_server_file && \
		func_download &
		wait
		echo "Program Close !"
		func_v2_running &
		logger -t "[v2ray]" "开始运行…"
	else
		exit 0
	fi
}

func_stop(){
	func_Del_rule &
	sleep 2
	if [ $(nvram get ss_enable) = "0" ]
	then
		[ -d "$v2_home" ] && rm -rf $v2_home
	fi
	[ -f "/var/run/v2ray-watchdog.pid" ] && rm -rf /var/run/v2ray-watchdog.pid
	logger -t "[v2ray]" "已停止运行 !"
}

case "$1" in
start)
	func_start
	;;
stop)
	func_stop
	;;
v2_file)
	v2_server_file
	;;
v2_ipt)
	func_ipt_running
	exit 0
	;;
*)
	echo "Usage: $0 { start | stop | v2_file | v2_ipt }"
	exit 1
	;;
esac

