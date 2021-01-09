#!/bin/sh
# Compile:by-lanse	2021-01-09

export PATH=$PATH:/usr/bin:/tmp/adbyby/bin
export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/usr/bin:/tmp/adbyby/bin

adbyby_enable=$(nvram get adbyby_enable)
http_username=$(nvram get http_username)
adbyby_update=$(nvram get adbyby_update)
adbyby_update_hour=$(nvram get adbyby_update_hour)
adbyby_update_min=$(nvram get adbyby_update_min)
wan_mode=$(nvram get adbyby_set)
abp_mode=$(nvram get adbyby_adb_update)

TIME_SCRIPT="/etc/storage/cron/crontabs/$http_username"
STORAGE_DNSMASQ="/etc/storage/dnsmasq/dnsmasq.conf"
HOSTS_HOME="/etc/storage/dnsmasq.ad"
HS_TV="$HOSTS_HOME/hosts_ad"

ADBYBY_HOME="/tmp/adbyby"
TMP_HOME="/tmp/adbyby/bin"
GZ_HOME="$TMP_HOME/data"

add_cron()
{
    if [ "$adbyby_update" -eq 0 ] ; then
        sed -i '/adbyby.sh/d' "$TIME_SCRIPT" && sleep 2
        cat >> "$TIME_SCRIPT" << EOF
$adbyby_update_min $adbyby_update_hour * * * /bin/sh /usr/bin/adbyby.sh G 2>&1 >/dev/null &
EOF
        logger "adbyby" "设置每天$adbyby_update_hour时$adbyby_update_min分,自动更新规则！"
    elif [ "$adbyby_update" -eq 1 ] ; then
        sed -i '/adbyby.sh/d' "$TIME_SCRIPT" && sleep 2
        cat >> "$TIME_SCRIPT" << EOF
*/$adbyby_update_min */$adbyby_update_hour * * * /bin/sh /usr/bin/adbyby.sh G >/dev/null 2>&1
EOF
        logger "adbyby" "设置每隔$adbyby_update_hour时$adbyby_update_min分,自动更新规则！"
    elif [ "$adbyby_update" -eq 2 ] ; then
        sed -i '/adbyby.sh/d' "$TIME_SCRIPT" && sleep 2
    fi
}

Black_white_list()
{
    ad_whitelist=$ADBYBY_HOME/ad_whitelist
    adb_whitconf=/tmp/adbyby/ad_whitelist.conf
    storage_whitelist="/etc/storage/ad_whitelist.sh"
    if [ ! -f "$storage_whitelist" ] || [ ! -s "$storage_whitelist" ] ; then
        cp -f $ad_whitelist $storage_whitelist && \
        chmod 644 "$storage_whitelist"
    fi
    grep -v '^!' "$storage_whitelist" | sed -e "/^#/d /^\s*$/d" > $adb_whitconf && sleep 2
    if [ -f "$TMP_HOME/adhook.ini" ] || [ -s "$adb_whitconf" ] ; then
        if [ "$adb_whitconf" != "" ] ; then
            logger "adbyby" "添加过滤白名单地址"
            sed -Ei '/whitehost=/d' "$TMP_HOME/adhook.ini"
            echo whitehost=$adb_whitconf >> "$TMP_HOME/adhook.ini"
            sed -Ei '/http/d' "$GZ_HOME/user.txt"
            echo @@\|http://\$domain=$(echo "$adb_whitconf" | tr , \|) >> "$GZ_HOME/user.txt"
        else
            logger "过滤白名单地址未定义,已忽略..."
        fi
        sleep 2
    fi
}

Black_black_list()
{
    adb_black=$ADBYBY_HOME/ad_blacklist
    storage_hosts="$HS_TV/ad_blacklist.conf"
    storage_black="/etc/storage/ad_blacklist.sh"
    if [ ! -f "$storage_black" ] || [ ! -s "$storage_black" ] ; then
        cp -f "$adb_black" "$storage_black" && \
        chmod 644 "$storage_black"
    fi
    if [ ! -f "$storage_hosts" ] || [ ! -s "$storage_hosts" ] ; then
        sed -i '/hosts_ad/d' "$STORAGE_DNSMASQ" && sleep 2
        cat >> "$STORAGE_DNSMASQ" << EOF
addn-hosts=$HOSTS_HOME/hosts_ad/
EOF
        sleep 2
        cat > /tmp/tmp_blacklist << EOF
## 自定义 hosts 设置
## 2019 by.lanse
127.0.0.1 localhost
::1 localhost
::1    ip6-localhost
::1    ip6-loopback
# 192.168.2.80    Boo
EOF
        grep -v '^!' $storage_black | sed -E -e "/^#/d /^\s*$/d" -e "s:||:0.0.0.0 :" >> /tmp/tmp_blacklist && \
        mv -f /tmp/tmp_blacklist $storage_hosts && sleep 2
    else
        sed -i '/hosts_ad/d' "$STORAGE_DNSMASQ" && sleep 2
        if [ -s "$storage_hosts" ]
        then
            cat >> "$STORAGE_DNSMASQ" << EOF
addn-hosts=$HOSTS_HOME/hosts_ad/
EOF
        fi
    fi
    sleep 2
}

Black_blackip()
{
    adb_blackip=$ADBYBY_HOME/ad_black_IP
    storage_blackip="/etc/storage/ad_black_ip.sh"
    if [ ! -f "$storage_blackip" ] || [ ! -s "$storage_blackip" ]
    then
        cp -f "$adb_blackip" "$storage_blackip" && \
        chmod 644 "$storage_blackip"
    fi
    if [ -f "$storage_blackip" ] || [ -s "$storage_blackip" ]
    then
        ipset -exist create blackip hash:net hashsize 64
        awk '!/^$/&&!/^#/{printf("add blackip %s'" "'\n",$0)}' "$storage_blackip" | ipset restore
        sleep 2
        iptables -I FORWARD -m set --match-set blackip dst -j DROP
        iptables -I OUTPUT -m set --match-set blackip dst -j DROP
        sleep 2
    fi
}

Black_custom()
{
    adb_custom=$ADBYBY_HOME/ad_custom
    storage_custom="/etc/storage/ad_custom.sh"
    if [ ! -f "$storage_custom" ] || [ ! -s "$storage_custom" ] ; then
        cp -f $adb_custom $storage_custom && \
        chmod 644 $storage_custom
    else
        grep -v "^$" $storage_custom > $GZ_HOME/user.txt
    fi
    sed -Ei '/http/d' "$GZ_HOME/user.txt"
    echo @@\|http://\$domain=$(echo $adb_whitconf | tr , \|) >> "$GZ_HOME/user.txt" &
    sleep 2
}

rule_hosts()
{
    hosts_ad=$(nvram get hosts_ad)
    tv_hosts=$(nvram get tv_hosts)
    nvram set adbyby_hostsad=0
    nvram set adbyby_tvbox=0
    if [ "$hosts_ad" = "1" ] ; then
        sed -i '/hosts_ad/d' "$STORAGE_DNSMASQ" && sleep 2
        cat >> "$STORAGE_DNSMASQ" << EOF
addn-hosts=$HOSTS_HOME/hosts_ad/
EOF
        wget -t 5 -T 10 -c --no-check-certificate -O- "https://cdn.jsdelivr.net/gh/vokins/yhosts/hosts" \
        | sed -E -e '/#/d' -e '/^\s*$/d; s/127.0.0.1/0.0.0.0/' > $HS_TV/hosts &
        chmod 644 $HS_TV/hosts &
        wait
        echo "download hosts file !"
        if [ -f "$HS_TV/hosts" ] ; then
            nvram set adbyby_hostsad=$(grep -v '^!' $HS_TV/hosts | wc -l)
        fi
    else
        [ ! -f "$storage_hosts" ] && [ ! -f "$HS_TV/tvhosts" ] && sed -i '/hosts_ad/d' $STORAGE_DNSMASQ
        rm -rf $HS_TV/hosts
    fi
    if [ "$tv_hosts" = "1" ] ; then
        sed -i '/hosts_ad/d' "$STORAGE_DNSMASQ" && sleep 2
        cat >> "$STORAGE_DNSMASQ" << EOF
addn-hosts=$HOSTS_HOME/hosts_ad/
EOF
        wget --no-check-certificate -O- "http://winhelp2002.mvps.org/hosts.txt" \
        |sed -E -e "s/#.*$//" -e "/^$/d" -e "/localhost/d" -e '/^[[:space:]]*$/d' > $HS_TV/tvhosts &
        chmod 644 $HS_TV/tvhosts &
        wait
        echo "download tvhosts file !"
        if [ -f "$HS_TV/tvhosts" ] ; then
            nvram set adbyby_tvbox=$(grep -v '^!' $HS_TV/tvhosts | wc -l)
        fi
    else
        [ ! -f "$storage_hosts" ] && [ ! -f "$HS_TV/hosts" ] && sed -i '/hosts_ad/d' "$STORAGE_DNSMASQ"
        rm -rf $HS_TV/tvhosts
    fi
    sleep 2
}

rule_update()
{
    if [ -f "$TMP_HOME/adupdate.sh" ] ; then
        #sh $TMP_HOME/adupdate.sh &
    fi
    nvram set adbyby_ltime=$(head -1 $GZ_HOME/lazy.txt | awk -F' ' '{print $3,$4}')
    nvram set adbyby_vtime=$(head -1 $GZ_HOME/video.txt | awk -F' ' '{print $3,$4}')
    sleep 2
}

func_abp_up()
{
    if [ ! -f "$HOSTS_HOME/dnsmasq.adblock" ] ; then
        $ADBYBY_HOME/adblock.sh 2>&1 >/dev/null &
        wait
        echo "download adblock file !"
        func_adblock_gz &
    fi
}

func_adblock_gz()
{
    if [ "$wan_mode" = "1" ] || [ "$abp_mode" = "1" ]
    then
        nvram set adbyby_adb=0
        if [ -f "$HOSTS_HOME/dnsmasq.adblock" ] ; then
            if grep -q "adblock.sh" "$TIME_SCRIPT"
            then
                echo 'Startup code exists'
            else
                sed -i '/adblock.sh/d' "$TIME_SCRIPT" && sleep 2
                cat >> "$TIME_SCRIPT" << EOF
45 5 * * * $ADBYBY_HOME/adblock.sh 2>&1 >/dev/null &
EOF
            sleep 2
            fi
        fi
        nvram set adbyby_adb=$(grep -v '^!' $HOSTS_HOME/dnsmasq.adblock | wc -l) && \
        sed -i '/conf-file/d' $STORAGE_DNSMASQ && sleep 2
        cat >> $STORAGE_DNSMASQ << EOF
conf-file=$HOSTS_HOME
EOF
        sleep 2 && logger "AD" "HOSTS 规则加载完成."
        restart_dhcpd
    else
        sed -i '/conf-file/d' "$STORAGE_DNSMASQ"
        sed -i '/adblock.sh/d' "$TIME_SCRIPT"
        rm -rf $HOSTS_HOME/dnsmasq.adblock
        nvram set adbyby_adb=0
        sleep 2 
    fi
}

del_rule()
{
    if grep -q "adbyby.sh" "$TIME_SCRIPT"
    then
        sed -i '/adbyby.sh/d' "$TIME_SCRIPT"
        sleep 2
    fi
    if grep -q "adblock.sh" "$TIME_SCRIPT"
    then
        sed -i '/adblock.sh/d' "$TIME_SCRIPT"
        sleep 2
    fi
    if grep -q "ad_watchcat" "$TIME_SCRIPT"
    then
        sed -i '/ad_watchcat/d' "$TIME_SCRIPT"
        sleep 2
    fi
    if grep -q "dnsmasq.ad" "$STORAGE_DNSMASQ"
    then
        sed -i '/conf-file/d /hosts_ad/d' $STORAGE_DNSMASQ
    fi
}

adbyby_folder()
{
    if [ ! -f "$TMP_HOME/adbyby" ]
    then
        logger "adbyby" "adbyby程序文件不存在,正在解压..." && sleep 25
        #tar zxf "/etc_ro/adbyby.tar.gz" "adbyby/bin" -C "/tmp"
        tar zxf "/etc_ro/adbyby.tar.gz" -C "/tmp" &
        sleep 3
    fi
}

function_install()
{
    if [ $(nvram get adbyby_enable) = 1 ] ; then
        pids=$(ps |grep "$TMP_HOME/adbyby" |grep -v "grep" |wc -l)
        if [ $pids -eq 0 ] ; then
            $TMP_HOME/adbyby &
            sleep 2
            port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
            if [ $port -eq 0 ] ; then
                iptables -t nat -A PREROUTING -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 8118
            fi
            if grep -q "ad_watchcat" "$TIME_SCRIPT"
            then
                echo 'Startup code exists'
            else
                sed -i '/ad_watchcat/d' "$TIME_SCRIPT" && sleep 2
                cat >> "$TIME_SCRIPT" << EOF
*/30 * * * * $ADBYBY_HOME/ad_watchcat 2>&1 >/dev/null &
EOF
            sleep 2
            fi
        fi
    else
        ipt_restore &
        exit 0
    fi
}

ipt_restore()
{
    port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
    if [ $port -ge 1 ] ; then
        iptables -t nat -D PREROUTING -p tcp -m tcp --dport 80 -j REDIRECT --to-ports 8118
    fi
    sleep 1
    ipset flush blackip 2>/dev/null &
    iptables -D FORWARD -m set --match-set blackip dst -j DROP 2>/dev/null
    iptables -D OUTPUT -m set --match-set blackip dst -j DROP 2>/dev/null
    sleep 2
}

adbyby_start()
{
    if [ "$adbyby_enable" = "1" ] ; then
        del_rule &
        adbyby_folder &
        wait
        echo "Adbyby Unzip End !"
        logger "adbyby" "成功解压至:/tmp/adbyby"
        rule_update &
        if [ "$wan_mode" = "2" ] ; then
                function_install &
        else
                sed -i '/conf-file/d /hosts_ad/d' $STORAGE_DNSMASQ && sleep 2
                [ ! -d "$HS_TV" ] && mkdir -p "$HS_TV" && chmod +X "$HS_TV"
                add_cron && \
                Black_white_list && \
                Black_black_list && \
                Black_blackip && \
                Black_custom &
                if [ "$wan_mode" = "0" ] ; then
                    if [ -z "$(pidof adbyby)" ] ; then
                        function_install &
                    fi
                else
                    ipt_restore
                fi
                rule_hosts &
                func_adblock_gz &
        fi
        wait
        echo "Adbyby Started..."
        logger "adbyby" "Adbyby 启动并开始运行."
    fi
}

adbyby_stop()
{
    logger "adbyby" "卸载 Adbyby !"
    del_rule &
    if [ -n "$(pidof adbyby)" ] ; then
        killall adbyby >/dev/null 2>&1 &
        sleep 2
    fi
    ipt_restore &
    if [ "$adbyby_enable" = "0" ] ; then
        nvram set adbyby_adb=$(grep -v '^!' $HOSTS_HOME/dnsmasq.adblock | wc -l) &
        nvram set adbyby_hostsad=$(grep -v '^!' $HS_TV/hosts | wc -l) &
        nvram set adbyby_tvbox=$(grep -v '^!' $HS_TV/tvhosts | wc -l) &
        [ -f /var/log/adbyby_watchdog.log ] && rm -f /var/log/adbyby_watchdog.log
        sleep 2 && rm -rf $ADBYBY_HOME &
        sleep 2 && rm -rf $HOSTS_HOME &
        rm -f /tmp/adbyby.updated
        sleep 2
    fi
    ipset -X blackip 2>/dev/null &
    nvram set adbyby_ltime=0
    nvram set adbyby_vtime=0
    logger "adbyby" "Adbyby已关闭."
}

case "$1" in
start)
    adbyby_start
    ;;
stop)
    adbyby_stop
    ;;
restart)
    adbyby_stop
    adbyby_start
    ;;
updateadb)
    func_abp_up
    ;;
*)
    echo "check"
    ;;
esac

