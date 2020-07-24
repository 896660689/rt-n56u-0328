#!/bin/sh
# Compile:by-lanse	2020-07-03

v2_home="/tmp/v2fly"
v2_json="$v2_home/config.json"
ss_mode=$(nvram get ss_mode)
STORAGE="/etc/storage"
SSR_HOME="$STORAGE/shadowsocks"
STORAGE_V2SH="$STORAGE/storage_v2ray.sh"
SS_LOCAL_PORT_LINK=$(nvram get ss_local_port)
ss_tunnel_local_port=$(nvram get ss-tunnel_local_port)
SS_LAN_IP=$(nvram get lan_ipaddr)

v2_address=$(sed -n "2p" $STORAGE_V2SH |cut -f 2 -d ":")
v2_port=$(sed -n "3p" $STORAGE_V2SH |cut -f 2 -d ":")
v2_userid=$(sed -n "4p" $STORAGE_V2SH |cut -f 2 -d ":")
v2_alterId=$(sed -n "5p" $STORAGE_V2SH |cut -f 2 -d ":")
v2_confidentiality=$(sed -n "6p" $STORAGE_V2SH |cut -f 2 -d ":")
v2_docking_mode=$(sed -n "7p" $STORAGE_V2SH |cut -f 2 -d ":")
v2_domain_name=$(sed -n "8p" $STORAGE_V2SH |cut -f 2 -d ":")
v2_route=$(sed -n "9p" $STORAGE_V2SH |cut -f 2 -d ":")
v2_tls=$(sed -n "10p" $STORAGE_V2SH |cut -f 2 -d ":")

func_download(){
    if [ ! -f "$v2_home/v2ray" ]
    then
        mkdir -p "$v2_home"
        curl -k -s -o $v2_home/v2ray --connect-timeout 10 --retry 3 https://cdn.jsdelivr.net/gh/896660689/OS/v2fly/v2ray && \
        chmod 777 "$v2_home/v2ray"
    fi
}

v2_server_file(){
    if [ ! -f "$STORAGE_V2SH" ] || [ ! -s "$STORAGE_V2SH" ]
    then
        cat > "$STORAGE_V2SH" <<EOF
## -------- 以下修改账号信息，文本格式固定勿改动! -------- ##
#服务器账号:zzmm01.qlioilp.xyz
#服务器端口:11183
#用户ID:d387ddb4-bcaa-11ea-8c26-0050569124d1
#额外ID:2
#加密方式:auto
#传输协议:ws
#伪装域名:
#路径:/X1m6BlMk/
#TLS:
## ---------- END ---------- ##
EOF
    chmod 644 "$STORAGE_V2SH"
    fi
}

v2_tmp_json(){
        cat > "$v2_json" <<EOF
{
  "log": {
    "access": "none",
    "error": "none",
    "loglevel": "warning"
  },
  "dns": {
    "servers": [
      "208.67.220.220",
      "176.103.130.131",
      "8.8.4.4",
      "localhost"
    ]
  },
  "policy": {
    "levels": {
      "5": {
        "handshake": 4,
        "connIdle": 300,
        "uplinkOnly": 0,
        "downlinkOnly": 0,
        "statsUserUplink": false,
        "statsUserDownlink": false,
        "bufferSize": 0
      }
    },
    "system": {
      "statsInboundUplink": false,
      "statsInboundDownlink": false
    }
  },
  "inbounds": [
    {
      "port": $SS_LOCAL_PORT_LINK,
      "listen": "::",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true,
        "ip": "127.0.0.1"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vmess",
      "tag": "proxy",
      "settings": {
        "vnext": [
          {
            "address": "$v2_address",
            "port": $v2_port,
            "users": [
              {
                "id": "$v2_userid",
                "alterId": $v2_alterId,
                "security": "$v2_confidentiality"
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "$v2_docking_mode",
        "security": "$v2_tls",
        "tlsSettings": {
          "allowInsecure": true,
          "serverName": "$v2_domain_name"
        },
        "wsSettings": {
          "connectionReuse": true,
          "path": "$v2_route",
          "headers": {
            "Host": "$v2_domain_name"
          }
        }
      },
      "mux": {
        "enabled": true
      }
    },
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "settings": {},
      "tag": "blocked"
    }
  ],
  "routing": {
    "rules": [        
      {
        "type": "field",
        "outboundTag": "direct",
        "domain": [
          "domain:speedtest.net"
        ]
      }
    ]
  }
}
EOF
}

func_Del_rule(){
    if [ -n "$(pidof v2ray)" ] ; then
        killall v2ray >/dev/null 2>&1 &
        sleep 2
    fi
}

func_v2_running(){
    v2_tmp_json
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
*)
    echo "Usage: $0 { start | stop | v2_file }"
    exit 1
    ;;
esac

