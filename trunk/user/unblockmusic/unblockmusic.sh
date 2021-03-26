#!/bin/sh

export PATH=$PATH:/etc/storage/unblockmusic
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/etc/storage/unblockmusic

check_ss(){
if [ $(nvram get ss_mode) = "2" ] ; then
    logger -t "Music" "系统检测到SS 使用 [gfwlist] 代理模式, 请先调整 [Shadowsocks] 代理模式,再重启音乐解锁, 程序将退出!"
    nvram set wyy_enable=0
    exit 0
fi
}

STORAGE_DIR="/etc/storage"
ENABLE=$(nvram get wyy_enable)
TYPE=$(nvram get wyy_musicapptype)
APPTYPE=$(nvram get wyy_apptype)
FLAC=$(nvram get wyy_flac)

CLOUD=$(nvram get wyy_cloudserver)
if [ "$CLOUD" = "coustom" ]; then
    CLOUD=$(nvram get wyy_coustom_server)
fi
cloudadd=$(echo "$CLOUD" | awk -F ':' '{print $1}')
cloudhttp=$(echo "$CLOUD" | awk -F ':' '{print $2}')
cloudhttps=$(echo "$CLOUD" | awk -F ':' '{print $3}')
cloudip=$(check_host $cloudadd)
ipt_n="iptables -t nat"

check_host(){
    local host=$1
    if echo $host | grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
        hostip=$host
    elif [ "$host" != "${host#*:[0-9a-fA-F]}" ]; then
        hostip=$host
    else
        hostip=$(ping $host -W 1 -s 1 -c 1 | grep PING | cut -d'(' -f 2 | cut -d')' -f1)
        if echo $hostip | grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
            hostip=$hostip
        else
            hostip="127.0.0.1"
        fi
    fi
    echo -e $hostip
}

ip_rule(){
num=`nvram get wyy_staticnum_x`
if [ $num -ne 0 ]; then
    for i in $(seq 1 $num)
    do
        j=`expr $i - 1`
        ip=`nvram get wyy_ip_x$j`
        mode=`nvram get wyy_ip_road_x$j`
        case "$mode" in
        http)
            ipset -! add music_http $ip
            ;;
        https)
            ipset -! add music_https $ip
            ;;
        disable)
            ipset -! add music_http $ip
            ipset -! add music_https $ip
            ;;
        esac
    done
fi
}

add_rule(){
    ipset -! -N music hash:ip
    ipset -! -N music_http hash:ip
    ipset -! -N music_https hash:ip
    $ipt_n -N CLOUD_MUSIC
    $ipt_n -A CLOUD_MUSIC -d 0.0.0.0/8 -j RETURN
    $ipt_n -A CLOUD_MUSIC -d 10.0.0.0/8 -j RETURN
    $ipt_n -A CLOUD_MUSIC -d 127.0.0.0/8 -j RETURN
    $ipt_n -A CLOUD_MUSIC -d 169.254.0.0/16 -j RETURN
    $ipt_n -A CLOUD_MUSIC -d 172.16.0.0/12 -j RETURN
    $ipt_n -A CLOUD_MUSIC -d 192.168.0.0/16 -j RETURN
    $ipt_n -A CLOUD_MUSIC -d 224.0.0.0/4 -j RETURN
    $ipt_n -A CLOUD_MUSIC -d 240.0.0.0/4 -j RETURN
    if [ "$APPTYPE" != "cloud" ]; then
        $ipt_n -A CLOUD_MUSIC -p tcp -m set ! --match-set music_http src --dport 80 -j REDIRECT --to-ports 5200
        $ipt_n -A CLOUD_MUSIC -p tcp -m set ! --match-set music_https src --dport 443 -j REDIRECT --to-ports 5201
    else
        $ipt_n -A CLOUD_MUSIC -p tcp -m set ! --match-set music_http src --dport 80 -j DNAT --to $cloudip:$cloudhttp
        $ipt_n -A CLOUD_MUSIC -p tcp -m set ! --match-set music_https src --dport 443 -j DNAT --to $cloudip:$cloudhttps
    fi
    $ipt_n -I PREROUTING -p tcp -m set --match-set music dst -j CLOUD_MUSIC
    iptables -I OUTPUT -d 223.252.199.10 -j DROP
    ip_rule
}

del_rule(){
    kill -9 $(busybox ps -w | grep UnblockNeteaseMusic | grep -v grep | awk '{print $1}') >/dev/null 2>&1
    kill -9 $(busybox ps -w | grep logcheck.sh | grep -v grep | awk '{print $1}') >/dev/null 2>&1
    iptables-save -c | grep -v CLOUD_MUSIC | iptables-restore -c && sleep 2
    iptables -D OUTPUT -d 223.252.199.10 -j DROP 2>/dev/null
    ipset -X music_http 2>/dev/null
    ipset -X music_https 2>/dev/null
    if grep -q "dnsmasq.music" "$STORAGE_DIR/dnsmasq/dnsmasq.conf"
    then
        sed -i '/dnsmasq.music/d' $STORAGE_DIR/dnsmasq/dnsmasq.conf
        restart_dhcpd && sleep 2
    fi
}

set_firewall(){
    mkdir -p $STORAGE_DIR/unblockmusic/dnsmasq.music
    cat > "$STORAGE_DIR/unblockmusic/dnsmasq.music/dnsmasq-163.conf" <<EOF
ipset=/.music.163.com/music
ipset=/interface.music.163.com/music
ipset=/interface3.music.163.com/music
ipset=/apm.music.163.com/music
ipset=/apm3.music.163.com/music
ipset=/clientlog.music.163.com/music
ipset=/clientlog3.music.163.com/music
EOF
    chmod 644 "$STORAGE_DIR/unblockmusic/dnsmasq.music/dnsmasq-163.conf"
    if grep -q "dnsmasq.music" "$STORAGE_DIR/dnsmasq/dnsmasq.conf"
    then
        sed -i '/dnsmasq.music/d' $STORAGE_DIR/dnsmasq/dnsmasq.conf
    fi
    cat >> $STORAGE_DIR/dnsmasq/dnsmasq.conf << EOF
conf-dir=$STORAGE_DIR/unblockmusic/dnsmasq.music/
EOF
    restart_dhcpd && sleep 2
    add_rule
}

wyy_folder(){
    if [ ! -d "$STORAGE_DIR/unblockmusic" ] ; then
        tar zxf "/etc_ro/unblockmusic.tar.gz" -C "$STORAGE_DIR" && sleep 2
    fi
}

wyy_start()
{
    [ $ENABLE -eq "0" ] && exit 0
    wyy_folder &
    if [ "$TYPE" = "default" ]; then
        musictype=" "
    else
        musictype="-o $TYPE"
    fi
    if [ "$APPTYPE" == "go" ]; then
        if [ $FLAC -eq 1 ]; then
           ENABLE_FLAC="-b "
        fi
        UnblockNeteaseMusic $ENABLE_FLAC -p 5200 -sp 5202 -m 0 -c /$STORAGE_DIR/unblockmusic/music_certificate/server.crt -k /$STORAGE_DIR/unblockmusic/music_certificate/server.key -m 0 -e >/dev/null 2>&1 &
        logger -t "音乐解锁" "启动 Golang Version (http:5200, https:5201)"
    else
        kill -9 $(busybox ps -w | grep 'sleep 60m' | grep -v grep | awk '{print $1}') >/dev/null 2>&1
        $STORAGE_DIR/unblockmusic/UnblockNeteaseMusicCloud >/dev/null 2>&1 &
        logger -t "音乐解锁" "启动 Cloud Version - Server: $cloudip (http:$cloudhttp, https:$cloudhttps)"
    fi
    set_firewall
    if [ "$APPTYPE" != "cloud" ]; then
        $STORAGE_DIR/unblockmusic/logcheck.sh >/dev/null 2>&1 &
    fi
}

wyy_close()
{
    del_rule && \
    ipset -X music 2>/dev/null &
    [ -d "$STORAGE_DIR/unblockmusic" ] && rm -rf "$STORAGE_DIR/unblockmusic"
    logger -t "音乐解锁" "已关闭"
}

case $1 in
start)
    check_ss
    wyy_start
    ;;
stop)
    wyy_close
    ;;
restart)
    wyy_close
    wyy_start
    ;;
*)
    echo "check"
    #exit 0
    ;;
esac

