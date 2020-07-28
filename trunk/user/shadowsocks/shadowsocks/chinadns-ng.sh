#!/bin/sh
# Compile:by-lanse	2020-07-28

modprobe xt_set
modprobe ip_set_hash_ip
modprobe ip_set_hash_net

STORAGE="/etc/storage"
SSR_HOME="$STORAGE/shadowsocks"
DNSMASQ_RURE="$STORAGE/dnsmasq/dnsmasq.conf"
STORAGE_V2SH="$STORAGE/storage_v2ray.sh"
V2RUL=/tmp/V2mi.txt

ss_tunnel_local_port=$(nvram get ss-tunnel_local_port)

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
iptables-save -c | grep -v CNNG_ | iptables-restore -c && sleep 1
for setname in $(ipset -n list | grep "gateway"); do
    ipset destroy "$setname" 2>/dev/null
done
}

func_cdn_file(){
    logger -t "[CHINADNS-NG]" "下载 [cdn] 域名文件..."
    curl -k -s -o /tmp/cdn.txt --connect-timeout 10 --retry 3 https://gitee.com/bkye/rules/raw/master/cdn.txt
}

func_cnng_file(){
    /usr/bin/chinadns-ng -b 0.0.0.0 -l 65353 -c 114.114.114.114#53 -t 127.0.0.1#$ss_tunnel_local_port -4 chnroute >/dev/null 2>&1 &
    if grep -q "no-resolv" "$DNSMASQ_RURE"
    then
        sed -i '/no-resolv/d; /server=127.0.0.1/d' $DNSMASQ_RURE
    fi
    cat >> $DNSMASQ_RURE << EOF
no-resolv
server=127.0.0.1#65353
EOF
restart_dhcpd
}

func_lan_ip(){
ipset -! restore <<-EOF
create gateway hash:net hashsize 64
$(gen_lan_ip | sed -e "s/^/add gateway /")
EOF
}

gen_lan_ip(){
cat <<-EOF | grep -E "^([0-9]{1,3}\.){3}[0-9]{1,3}"
0.0.0.0/8
10.0.0.0/8
127.0.0.0/8
169.254.0.0/16
172.16.0.0/12
192.0.2.0/24
192.168.0.0/16
224.0.0.0/4
240.0.0.0/4
EOF
}

flush_ipt_file(){
FWI="/tmp/shadowsocks_iptables.save"
[ -n "$FWI" ] && echo '# firewall include file' >$FWI && \
chmod +x $FWI
return 0
}

func_cnng_ipt(){
if [ -s "$V2RUL" ]
then
    v2_address=$(sed -n "2p" $V2RUL |cut -f 2 -d ":")
else
    v2_address=$(sed -n "2p" $STORAGE_V2SH |cut -f 2 -d ":")
fi
ipt="iptables -t nat"

$ipt -N CNNG_OUT
$ipt -N CNNG_PRE

$ipt -A PREROUTING -j CNNG_OUT
$ipt -A OUTPUT -j CNNG_PRE
$ipt -A CNNG_PRE -d $v2_address -j RETURN
$ipt -A CNNG_PRE -m set --match-set gateway dst -j RETURN
$ipt -A CNNG_PRE -m set --match-set chnroute dst -j RETURN
#$ipt -A CNNG_OUT -m set --match-set chnroute dst -j RETURN
$ipt -A CNNG_OUT -p udp -d 127.0.0.1 --dport 53 -j REDIRECT --to-ports 65353

$ipt -A CNNG_OUT -p tcp -j CNNG_PRE
$ipt -A CNNG_PRE -p tcp -j REDIRECT --to-ports 12345

cat <<-CAT >>$FWI
iptables-save -c | grep -v CNNG_ | iptables-restore -c
iptables-restore -n <<-EOF
$(iptables-save | grep -E "CNNG_|^\*|^COMMIT" |\
sed -e "s/^-A \(OUTPUT\|PREROUTING\)/-I \1 1/")
EOF
CAT
return 0
}

func_start(){
    func_del_rule && \
    echo -e "\033[41;37m 部署 [CHINADNS-NG] 文件,请稍后...\e[0m\n"
    #func_cdn_file &
    wait
    echo "download cdn file !"
    func_del_ipt
    func_cnng_file
    func_lan_ip && \
    flush_ipt_file && \
    func_cnng_ipt && \
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

