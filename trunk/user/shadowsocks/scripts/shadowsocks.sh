#!/bin/sh
# Compile:by-lanse	2020-07-15

export PATH=$PATH:/etc/storage/shadowsocks
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/etc/storage/shadowsocks

ss_proc="/var/ss-redir"
ss_bin="ss-redir"
ss_json="/tmp/ss-redir.json"
STORAGE="/etc/storage"
SSR_HOME="$STORAGE/shadowsocks"
DNSMASQ_RURE="$STORAGE/dnsmasq/dnsmasq.conf"
TIME_SCRIPT="$STORAGE/cron/crontabs/$username"
dir_chnroute_file="$STORAGE/chinadns/chnroute.txt"
dir_gfwlist_file="$STORAGE/gfwlist/gfw_list.conf"
ss_folder="/etc_ro/shadowsocks.tar.gz"

username=$(nvram get http_username)
SS_ENABLE=$(nvram get ss_enable)
SS_TYPE=$(nvram get ss_type)	#0=ss;1=ssr
SS_LOCAL_PORT_LINK=$(nvram get ss_local_port)
SS_SERVER_LINK=$(nvram get ss_server)
SS_UDP=$(nvram get ss_udp)
SS_WATCHCAT=$(nvram get ss_watchcat)
SS_DNS=$(nvram get ss_dns)
SS_SERVER_PORT_LINK=$(nvram get ss_server_port)
ss_method=$(nvram get ss_method)
ss_password=$(nvram get ss_key)
ss_mtu=$(nvram get ss_mtu)
ss_timeout=$(nvram get ss_timeout)
ss_mode=$(nvram get ss_mode)	#0:Agente-Global;1:chnroute;2:gfwlist;3:v2ray
ss_router_proxy=$(nvram get ss_router_proxy)
ss_lower_port_only=$(nvram get ss_lower_port_only)
ss_tunnel_local_port=$(nvram get ss-tunnel_local_port)
ss_tunnel_remote=$(nvram get ss-tunnel_remote)

SS2_SERVER_LINK=$(nvram get ss2_server)
SS2_SERVER_PORT_LINK=$(nvram get ss2_server_port)
ss2_method=$(nvram get ss2_method)
ss2_password=$(nvram get ss2_key)
ss2_protocol=$(nvram get ss2_protocol)
ss2_proto_param=$(nvram get ss2_proto_param)
ss2_obfs=$(nvram get ss2_obfs)
ss2_obfs_param=$(nvram get ss2_obfs_param)
v2_address=$(sed -n "2p" /etc/storage/storage_v2ray.sh |cut -f 2 -d ":")

check_music(){
if [ $(nvram get wyy_enable) = "1" ] && [ $(nvram get sdns_enable) = "1" ]; then
    logger -t "[ShadowsocksR]" "系统检测到音乐解锁或 [SMT] 正在运行, 请改变使用 [gfwlist] 以外其它代理模式, 再重启 [ShadowsocksR], 程序将退出!"
    nvram get ss_enable=0
    exit 0
fi
}

if [ "${SS_TYPE:-0}" = "0" ] ; then
    ln -sf /usr/bin/ss-orig-redir $ss_proc
elif [ "${SS_TYPE:-0}" = "1" ] ; then
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
    if [ "$SS_UDP" = "1" ]
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
        bp=${bp}" -B $dir_chnroute_file"
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
    sh -c "$ss_bin -c $ss_json $(get_arg_udp) & "
    return $?
}

func_start_ss_rules(){
    ss-rules -f
    sh -c "ss-rules -s $SS_SERVER_LINK -l $SS_LOCAL_PORT_LINK $(get_wan_bp_list) -d SS_SPEC_WAN_AC $(get_ipt_ext) $(get_arg_out) $(get_arg_udp)"
    return $?
}

func_ss_Close(){
    loger $ss_bin "stop"; ss-rules -f &
    if [ -n "$(pidof ss-redir)" ] ; then
        killall ss-redir >/dev/null 2>&1 &
        sleep 2
    fi
    kill -9 $(busybox ps -w | grep dns-forwarder | grep -v grep | awk '{print $1}') >/dev/null 2>&1
    kill -9 $(busybox ps -w | grep dnsproxy | grep -v grep | awk '{print $1}') >/dev/null 2>&1
    kill -9 $(busybox ps -w | grep dns2tcp | grep -v grep | awk '{print $1}') >/dev/null 2>&1
    if [ -n "$(pidof pdnsd)" ] ; then
        killall pdnsd >/dev/null 2>&1 &
        sleep 2
    fi
    iptables -t nat -X gfwlist >/dev/null 2>&1
    iptables-save -c | grep -v "gfwlist" | iptables-restore -c && sleep 2
    ipset flush gfwlist 2>/dev/null &
    sleep 2
    if grep -q "ssr-watchcat" "$TIME_SCRIPT"
    then
        sed -i '/ssr-watchcat/d' "$TIME_SCRIPT" >/dev/null 2>&1
        sleep 2
    fi
    if grep -q "v2ray-watchdog" "$TIME_SCRIPT"
    then
        sed -i '/v2ray-watchdog/d' "$TIME_SCRIPT" >/dev/null 2>&1
        sleep 2
    fi
    if grep -q "gfwlist" "$DNSMASQ_RURE"
    then
        sed -i '/listen-address/d; /min-cache/d; /gfwlist/d; /log/d' $DNSMASQ_RURE &
    fi
}

func_ss_down(){
    if [ "$SS_ENABLE" = "0" ]
    then
        [ -f /tmp/ss-redir.json ] && rm -rf /tmp/ss-redir.json && sleep 1
        [ -f /var/run/pdnsd.pid ] && rm -f /var/run/pdnsd.pid && sleep 1
        [ -f /tmp/ss-redir.json.main ] && rm -rf /tmp/ss-redir.json.main && sleep 1
        [ -f /tmp/ss-redir.json.backup ] && rm -rf /tmp/ss-redir.json.backup && sleep 1
        [ -d /var/pdnsd ] && rm -rf /var/pdnsd && sleep 1
        [ -d $STORAGE/gfwlist ] && rm -rf $STORAGE/gfwlist && sleep 1
        [ -d $STORAGE/chinadns ] && rm -rf $STORAGE/chinadns && sleep 1
        [ -f /tmp/shadowsocks_iptables.save ] && rm -rf /tmp/shadowsocks_iptables.save
    fi
}

func_gfwlist_list(){
    if [ ! -f "$STORAGE/ss_dom.sh" ] || [ ! -s "$STORAGE/ss_dom.sh" ]
    then
        cat > "$STORAGE/ss_dom.sh" <<EOF
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
        chmod 644 $STORAGE/ss_dom.sh
    fi
    if [ ! -f "$STORAGE/ss_pc.sh" ] || [ ! -s "$STORAGE/ss_pc.sh" ]
    then
        cat > "$STORAGE/ss_pc.sh" <<EOF
### 排除走 [ gfwlist ] 代理模式的域名白名单
### 只填入网址名称或关键字即可,如下:
#speedtest.cn

EOF
        chmod 644 $STORAGE/ss_pc.sh
    fi
    sh $SSR_HOME/v2ray.sh v2_file
}

func_gen_ss_json(){
    cat > "$ss_json.main" <<EOF
{
    "server": "$SS_SERVER_LINK",
    "server_port": $SS_SERVER_PORT_LINK,
    "password": "$ss_password",
    "method": "$ss_method",
    "timeout": $ss_timeout,
    "protocol": "$ss_protocol",
    "protocol_param": "$ss_proto_param",
    "obfs": "$ss_obfs",
    "obfs_param": "$ss_obfs_param",
    "local_address": "0.0.0.0",
    "local_port": $SS_LOCAL_PORT_LINK,
    "mtu": $ss_mtu
}
EOF
}

func_gen_ss2_json(){
    cat > "$ss_json.backup" <<EOF
{
    "server": "$SS2_SERVER_LINK",
    "server_port": $SS2_SERVER_PORT_LINK,
    "password": "$ss2_password",
    "method": "$ss2_method",
    "timeout": $ss_timeout,
    "protocol": "$ss2_protocol",
    "protocol_param": "$ss2_proto_param",
    "obfs": "$ss2_obfs",
    "obfs_param": "$ss2_obfs_param",
    "local_address": "0.0.0.0",
    "local_port": $SS_LOCAL_PORT_LINK,
    "mtu": $ss_mtu
}
EOF
}

func_gfwlist_import(){
    if [ -s "$STORAGE/ss_dom.sh" ]
    then
        cat $STORAGE/ss_dom.sh | grep -v '^#' | grep -v "^$" \
        |sed -e "/.*/s/.*/server=\/&\/127.0.0.1#"$ss_tunnel_local_port"\nipset=\/&\/gfwlist/" > $STORAGE/gfwlist/gfw_custom.conf && \
        chmod 644 $STORAGE/gfwlist/gfw_custom.conf
    fi
    if [ -s "$STORAGE/ss_pc.sh" ]
    then
        cat $STORAGE/ss_pc.sh | grep -v '^#' | grep -v "^$" \
        |awk '{printf("server=/%s/127.0.0.1\n", $1, $1 )}' >> $STORAGE/dnsmasq/dnsmasq.conf && \
        cat $STORAGE/dnsmasq/dnsmasq.conf |awk '!a[$0]++' > $STORAGE/dnsmasq/dmq2.servers && \
        mv -f $STORAGE/dnsmasq/dmq2.servers $STORAGE/dnsmasq/dnsmasq.conf
    fi
}

func_chnroute_file(){
    if [ ! -f "$dir_chnroute_file" ] || [ ! -s "$dir_chnroute_file" ] ; then
        [ ! -d $STORAGE/chinadns ] && mkdir -p "$STORAGE/chinadns"
        tar jxf "/etc_ro/chnroute.bz2" -C "$STORAGE/chinadns"
        chmod 644 "$dir_chnroute_file" && /sbin/mtd_storage.sh save
    fi
}

func_gfwlist_file(){
    /etc/storage/shadowsocks/update_gfwlist.sh force &
    sleep 2
    func_gfwlist_import
    sh $SSR_HOME/ss-gfwlist.sh -f
    if [ "$ss_mode" = "2" ]
    then
        sh -c "$SSR_HOME/ss-gfwlist.sh -s $SS_SERVER_LINK -l $SS_LOCAL_PORT_LINK"
        wait
        echo "Program Start…"
        $ss_bin -c $ss_json -b 0.0.0.0 -l $SS_LOCAL_PORT_LINK >/dev/null 2>&1 &
        sleep 2 && logger -t "[ShadowsocksR]" "使用 [gfwlist] 代理模式开始运行..."
    fi
}

func_port_agent_mode(){
    if [ "$ss_router_proxy" = "1" ]
    then
        killall -q pdnsd && killall -q dns-forwarder && killall -q dnsproxy && killall -q dns2tcp &
        logger "Local agent"
    elif [ "$ss_router_proxy" = "2" ]
    then
        /usr/bin/dns-forwarder -b 127.0.0.1 -p $ss_tunnel_local_port -s $ss_tunnel_remote >/dev/null 2>&1 &
        logger -t "[DNS]" "使用 [dns-forwarder] 解析方式 !"
    elif [ "$ss_router_proxy" = "3" ]
    then
        /usr/bin/dnsproxy -T -p $ss_tunnel_local_port -R 8.8.4.4 >/dev/null 2>&1 &
        logger -t "[DNS]" "使用 [dnsproxy] 解析方式 !"
    elif [ "$ss_router_proxy" = "4" ]
    then
        sh $SSR_HOME/ss-pdnsd.sh &
        logger -t "[DNS]" "使用 [pdnsd] 解析方式 !"
    elif [ "$ss_router_proxy" = "5" ]
    then
        /usr/bin/dns2tcp -L127.0.0.1#$ss_tunnel_local_port -R'8.8.8.8#53' &
        logger -t "[DNS]" "使用 [dns2tcp] 解析方式 !"
    else
        logger -t "[DNS]" "未开启代理解析 !"
    fi
}

func_cron(){
    if [ "$SS_WATCHCAT" = "1" ] ; then
        if [ "$ss_mode" = "3" ]
        then
            sed -i '/v2ray-watchdog/d' "$TIME_SCRIPT"
            cat >> "$TIME_SCRIPT" << EOF
*/3 * * * * $SSR_HOME/v2ray-watchdog 2>&1 >/dev/null &
EOF
        else
            sed -i '/ssr-watchcat/d' "$TIME_SCRIPT"
            cat >> "$TIME_SCRIPT" << EOF
*/3 * * * * $SSR_HOME/ssr-watchcat 2>&1 >/dev/null &
EOF
        fi
    fi
}

dog_restart(){
    if [ -n "$(pidof ss-redir)" ] ; then
        killall ss-redir >/dev/null 2>&1
    fi
    sleep 2 && $ss_bin -c $ss_json -b 0.0.0.0 -l $SS_LOCAL_PORT_LINK >/dev/null 2>&1 &
}

func_sshome_file(){
    [ ! -f "$ss_folder" ] && sleep 8
    if [ ! -d "$SSR_HOME" ] ; then
        sleep 10 && tar zxf "$ss_folder" -C "$STORAGE" && \
        /sbin/mtd_storage.sh save
    fi
}

func_v2fly(){
    /bin/sh $SSR_HOME/v2ray.sh start
}

func_redsocks(){
    /bin/sh $SSR_HOME/redsocks.sh start 127.0.0.1 $SS_LOCAL_PORT_LINK
    /bin/sh $SSR_HOME/redsocks.sh iptables $v2_address
}

func_chinadns_ng(){
    /bin/sh $SSR_HOME/chinadns-ng.sh start
}

func_start(){
    if [ "$SS_ENABLE" = "1" ]
    then
        if [ "$ss_mode" = "2" ]
        then
            check_music
        fi
        func_sshome_file && \
        if [ "$ss_mode" = "2" ]
        then
            func_gfwlist_file &
        else
            func_chnroute_file &
        fi
        wait
        echo "SSR FILE..."
        func_gfwlist_list && \
        func_port_agent_mode &
        if [ "$ss_mode" = "3" ]
        then
            logger -t "[v2ray]" "开始部署 [v2ray] 代理模式..."
            func_v2fly && \
            func_redsocks && \
            func_chinadns_ng &
        else
            echo -e "\033[41;37m 部署 [ShadowsocksR] 文件,请稍后...\e[0m\n"
            func_gen_ss_json && \
            func_gen_ss2_json && \
            ln -sf $ss_json.main $ss_json && \
            func_start_ss_redir && \
            func_start_ss_rules &
            wait
            echo "ShadowsocksR Started..."
            loger $ss_bin "ShadowsocksR Start up" || { ss-rules -f && loger $ss_bin "ShadowsocksR Start fail!"; }
        fi
        func_cron &
        sleep 2 && logger -t "[ShadowsocksR]" "开始运行"
    else
        exit 0
    fi
}

func_stop(){
    nvram set ss-tunnel_enable=0
    /usr/bin/ss-tunnel.sh stop &
    sleep 1 && /bin/sh $SSR_HOME/v2ray.sh stop &
    sleep 1 && /bin/sh $SSR_HOME/redsocks.sh stop
    sleep 1 && /bin/sh $SSR_HOME/chinadns-ng.sh stop
    sleep 1 && func_ss_Close &
    sleep 1 && func_ss_down &
    wait
    echo "Program Close ！"
    #ipset destroy gfwlist 2>/dev/null && sleep 2
    ipset -X gfwlist 2>/dev/null && \
    logger -t "[ShadowsocksR]" "已停止运行!"
}

case "$1" in
start)
    func_start
    ;;
stop)
    func_stop
    ;;
dog_up)
    dog_restart
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

