#!/bin/sh
# Compile:by-lanse	2020-06-30

STORAGE="/etc/storage"
SSR_HOME="$STORAGE/shadowsocks"
DNSMASQ_RURE="$STORAGE/dnsmasq/dnsmasq.conf"
STORAGE_V2SH="$STORAGE/storage_v2ray.sh"

ss_tunnel_local_port=$(nvram get ss-tunnel_local_port)
v2_address=$(sed -n "2p" $STORAGE_V2SH |cut -f 2 -d ":")

func_del_rule(){
    if [ -n "$(pidof chinadns-ng)" ] ; then
        killall chinadns-ng >/dev/null 2>&1 &
        sleep 2
    fi
    if grep -q "no-resolv" "$DNSMASQ_RURE"
    then
        sed -i '/no-resolv/d; /server=127.0.0.1/d' $DNSMASQ_RURE
    fi
}

func_del_ipt(){
    iptables-save -c | grep -v CNNG_OUT | iptables-restore -c && sleep 1
    iptables-save -c | grep -v CNNG_PRE | iptables-restore -c && sleep 1
    iptables-save -c | grep -v UDPCHAIN | iptables-restore -c && sleep 1
}

func_cnng_file(){
    logger -t "[CHINADNS-NG]" "下载 [cdn] 域名文件..."
    curl -k -s -o /tmp/cdn.txt --connect-timeout 10 --retry 3 https://gitee.com/bkye/rules/raw/master/cdn.txt
    /usr/bin/chinadns-ng -b 0.0.0.0 -l 65353 -c 223.5.5.5#53 -t 127.0.0.1#$ss_tunnel_local_port -4 china -m /tmp/cdn.txt >/dev/null 2>&1 &
    if grep -q "no-resolv" "$DNSMASQ_RURE"
    then
        sed -i '/no-resolv/d; /server=127.0.0.1/d' $DNSMASQ_RURE
    fi
    cat >> $DNSMASQ_RURE << EOF
no-resolv
server=127.0.0.1#65353
EOF
}

func_cnng_ipt(){
ipt="iptables -t nat"
ipt_m="iptables -t mangle"

$ipt -N CNNG_OUT
$ipt -N CNNG_PRE

$ipt -A CNNG_OUT -p tcp -j REDSOCKS
$ipt -A CNNG_OUT -p udp -d 127.0.0.1 --dport 53 -j REDIRECT --to-ports 65353
$ipt -I PREROUTING -j CNNG_PRE
$ipt -I OUTPUT -j CNNG_OUT

$ipt_m -N CNNG_OUT
$ipt_m -N CNNG_PRE
$ipt_m -N UDPCHAIN

$ipt_m -A UDPCHAIN -d $v2_address -j RETURN
$ipt_m -A UDPCHAIN -d 0.0.0.0/8 -j RETURN
$ipt_m -A UDPCHAIN -d 10.0.0.0/8 -j RETURN
$ipt_m -A UDPCHAIN -d 127.0.0.0/8 -j RETURN
$ipt_m -A UDPCHAIN -d 169.254.0.0/16 -j RETURN
$ipt_m -A UDPCHAIN -d 172.16.0.0/12 -j RETURN
$ipt_m -A UDPCHAIN -d 192.168.0.0/16 -j RETURN
$ipt_m -A UDPCHAIN -d 224.0.0.0/4 -j RETURN
$ipt_m -A UDPCHAIN -d 240.0.0.0/4 -j RETURN

$ipt_m -A UDPCHAIN -m set --match-set china dst -j RETURN
$ipt_m -A CNNG_OUT -p udp -j UDPCHAIN
$ipt_m -A PREROUTING -j CNNG_PRE
$ipt_m -A OUTPUT -j CNNG_OUT
}

func_start(){
    func_del_rule && \
    echo -e "\033[41;37m 部署 [CHINADNS-NG] 文件,请稍后...\e[0m\n"
    func_cnng_file &
    func_del_ipt && \
    func_cnng_ipt && sleep 2
    restart_dhcpd && \
    logger -t "[CHINADNS-NG]" "开始运行…"
}

func_stop(){
    func_del_rule && sleep 1
    func_del_ipt && sleep 1
    if [ $(nvram get ss_mode) = "3" ]
    then
        echo "V2RAY Not closed "
    else
        [ -f /tmp/cdn.txt ] && rm -rf /tmp/cdn.txt
    fi
    sleep 1 && logger -t "[CHINADNS-NG]" "已停止运行 !"
}

case "$1" in
start)
    func_start
    ;;
stop)
    func_stop
    ;;
*)
    echo "Usage: $0 { start | stop }"
    exit 1
    ;;
esac

