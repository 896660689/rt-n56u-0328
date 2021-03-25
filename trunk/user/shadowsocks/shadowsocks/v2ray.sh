#!/bin/sh
# Compile:by-lanse	2021-03-21

v2_home="/tmp/v2fly"
v2_json="$v2_home/config.json"
ss_mode=$(nvram get ss_mode)
STORAGE="/etc/storage"
dir_chnroute_file="$STORAGE/chinadns/chnroute.txt"
SSR_HOME="$STORAGE/shadowsocks"
STORAGE_V2SH="$STORAGE/storage_v2ray.sh"
SS_LOCAL_PORT_LINK=$(nvram get ss_local_port)
ss_tunnel_local_port=$(nvram get ss-tunnel_local_port)
SS_LAN_IP=$(nvram get lan_ipaddr)

V2RUL=/tmp/V2mi.txt

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
## ---- 以下粘贴 V2RAY URL 账号（应用后自动导入）-------- ##


## -- URL 账号为空时读取以下修改 V2RAY 账号信息，格式勿动! -- ##
#服务器账号
address:127.0.0.1
#服务器端口
port:12345
#用户ID
userid:v2ray-888
#额外ID
alterId:64
#传输协议
network:ws
#伪装域名
host:
路径
path:
安全协议
tls:
## ---------- END ---------- ##

EOF
    chmod 644 "$STORAGE_V2SH"
    fi
}

v2_addmi(){
if grep -q "vmess" "$STORAGE_V2SH"
then
    cat "$STORAGE_V2SH" | sed "s/vmess:\/\//vmess:/" | grep "vmess" | sed 's/:/\n/g' | sed '1d' | sed 's/}//g' \
    | /bin/base64 -d | sed -e 's/^ *//' -e 's/{/\n/g' -e 's/,/\n/g' -e 's/.$//g' -e 's/"//g' -e 's/: /:/g' \
    | sort -n | uniq > $V2RUL
fi
if [ -f "$V2RUL" ] ; then
    v2_address=$(cat $V2RUL | grep "add:" | awk -F '[:/]' '{print $2}')
    v2_port=$(cat $V2RUL | grep "port:" | awk -F '[:/]' '{print $2}')
    v2_userid=$(cat $V2RUL | grep -w "id" | awk -F '[:/]' '{print $2}')
    v2_alterId=$(cat $V2RUL | grep "aid:" | awk -F '[:/]' '{print $2}')
    v2_docking_mode=$(cat $V2RUL | grep "net:" | awk -F '[:/]' '{print $2}')
    v2_domain_name=$(cat $V2RUL | grep "host:" | sed 's/:/\n/g' | sed '1d')
    v2_route=$(cat $V2RUL | grep "path:" | sed 's/:/\n/g' | sed '1d')
    v2_tls=$(cat $V2RUL | grep "tls:" | awk -F '[:/]' '{print $2}')
else
    v2_address=$(cat $STORAGE_V2SH | grep "address" | awk -F '[:/]' '{print $2}')
    v2_port=$(cat $STORAGE_V2SH | grep "port" | awk -F '[:/]' '{print $2}')
    v2_userid=$(cat $STORAGE_V2SH | grep "userid" | awk -F '[:/]' '{print $2}')
    v2_alterId=$(cat $STORAGE_V2SH | grep "alterId" | awk -F '[:/]' '{print $2}')
    v2_docking_mode=$(cat $STORAGE_V2SH | grep "network" | awk -F '[:/]' '{print $2}')
    v2_domain_name=$(cat $STORAGE_V2SH | grep "host" | sed 's/:/\n/g' | sed '1d')
    v2_route=$(cat $STORAGE_V2SH | grep "path" | sed 's/:/\n/g' | sed '1d')
    v2_tls=$(cat $STORAGE_V2SH | grep "tls" | awk -F '[:/]' '{print $2}')
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
      "1.1.1.1",
      "208.67.220.220",
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
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
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
      "settings": {
        "vnext": [
          {
            "address": "$v2_address",
            "port": $v2_port,
            "users": [
              {
                "id": "$v2_userid",
                "alterId": $v2_alterId
              }
            ]
          }
        ]
      },
      "tag": "proxy",
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
        "enabled": true,
        "concurrency": 8
      }
    }
  ]
}
EOF
}

func_Del_rule(){
    if [ -n "$(pidof v2ray)" ] ; then
        killall v2ray &
        sleep 2
    fi
}

func_china_file(){
    if [ -f "$dir_chnroute_file" ] || [ -s "$dir_chnroute_file" ]
    then
        ipset -N chnroute hash:net
        sleep 3 && \
        awk '!/^$/&&!/^#/{printf("add chnroute %s'" "'\n",$0)}' $dir_chnroute_file | ipset restore &
    fi
}

func_Del_ipset(){
    for setname in $(ipset -n list | grep "chnroute"); do 
        ipset destroy "$setname" 2>/dev/null 
    done 
}

func_v2_running(){
    v2_addmi
    v2_tmp_json
    cd "$v2_home"
    ./v2ray >/dev/null 2>&1 &
}

func_start(){
    if [ "$ss_mode" = "3" ]
    then
        func_Del_rule && \
        func_china_file &
        echo -e "\033[41;37m 部署 [v2ray] 文件,请稍后...\e[0m\n"
        v2_server_file && \
        func_download &
        wait
        echo ""
        func_v2_running &
        logger -t "[v2ray]" "开始运行…"
    else
        exit 0
    fi
}

func_stop(){
    func_Del_ipset && \
    func_Del_rule &
    sleep 2
    if [ $(nvram get ss_enable) = "0" ]
    then
        [ -d "$v2_home" ] && rm -rf $v2_home
    fi
    [ -f "$V2RUL" ] && rm -rf $V2RUL
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

