#!/bin/sh
# Compile:by-lanse	2019-12-26

adbyby_enable=$(nvram get adbyby_enable)
adbyby_set=$(nvram get adbyby_set)
http_username=$(nvram get http_username)
adbyby_update=$(nvram get adbyby_update)
adbyby_update_hour=$(nvram get adbyby_update_hour)
adbyby_update_min=$(nvram get adbyby_update_min)
ipt_n="iptables -t nat"
wan_mode=$(nvram get adbyby_set)
Firewall_rules="/etc/storage/post_iptables_script.sh"
HOSTS_HOME="/etc/storage/dnsmasq.ad"
GZ_HOME="/tmp/adb/bin/data"
AD_HOME="/tmp/adb"

add_cron()
{
	if [ "$adbyby_update" -eq 0 ] ; then
		sed -i '/adbyby/d' /etc/storage/cron/crontabs/$http_username
		sed -i '/adbyby/d' /etc/storage/cron/crontabs/"$http_username"
cat >> /etc/storage/cron/crontabs/$http_username << EOF
$adbyby_update_min $adbyby_update_hour * * * /bin/sh /usr/bin/adbyby.sh G >/dev/null 2>&1
EOF
		logger "adbyby" "设置每天$adbyby_update_hour时$adbyby_update_min分,自动更新规则！"
	fi
	if [ "$adbyby_update" -eq 1 ] ; then
		sed -i '/adbyby/d' /etc/storage/cron/crontabs/$http_username
cat >> /etc/storage/cron/crontabs/$http_username << EOF
*/$adbyby_update_min */$adbyby_update_hour * * * /bin/sh /usr/bin/adbyby.sh G >/dev/null 2>&1
EOF
		logger "adbyby" "设置每隔$adbyby_update_hour时$adbyby_update_min分,自动更新规则！"
	fi
	if [ "$adbyby_update" -eq 2 ] ; then
		sed -i '/adbyby/d' /etc/storage/cron/crontabs/$http_username
	fi
}

Black_white_list()
{
	ad_whitelist=$AD_HOME/ad_whitelist
	ad_whitelistconf=$AD_HOME/ad_whitelist.conf
	whitelist_storage="/etc/storage/ad_whitelist.sh"
	if [ ! -f "$whitelist_storage" ] || [ ! -s "$whitelist_storage" ] ; then
		cp -f $ad_whitelist $whitelist_storage; chmod 644 $whitelist_storage
	fi
	grep -v '^!' $whitelist_storage | sed -e "/^#/d /^\s*$/d" > $ad_whitelistconf && sleep 2
	if [ -f "$AD_HOME/bin/adhook.ini" ] || [ -s "$ad_whitelistconf" ] ; then
		if [ "$ad_whitelistconf" != "" ] ; then
			logger "adbyby" "添加过滤白名单地址"
			sed -Ei '/whitehost=/d' "$AD_HOME/bin/adhook.ini"
			echo whitehost=$ad_whitelistconf >> "$AD_HOME/bin/adhook.ini"
			sed -Ei '/http/d' "$GZ_HOME/user.txt"
			echo @@\|http://\$domain=$(echo $ad_whitelistconf | tr , \|) >> "$GZ_HOME/user.txt"
		else
			logger "过滤白名单地址未定义,已忽略..."
		fi
	fi
	ad_blacklist=$AD_HOME/ad_blacklist
	ad_blacklistconf="$HOSTS_HOME/hosts/ad_blacklist.conf"
	blacklist_storage="/etc/storage/ad_blacklist.sh"
	[ ! -d "$HOSTS_HOME/hosts" ] && mkdir -p -m 755 $HOSTS_HOME/hosts
	if [ ! -f "$blacklist_storage" ] || [ ! -s "$blacklist_storage" ] ; then
		cp $ad_blacklist $blacklist_storage; chmod 644 $blacklist_storage
	fi
	[ ! -d "$HOSTS_HOME/hosts" ] && mkdir -p -m 755 $HOSTS_HOME/hosts
	if [ ! -f "$ad_blacklistconf" ] || [ ! -s "$ad_blacklistconf" ] ; then
		sed -i '/addn-hosts/d' /etc/storage/dnsmasq/dnsmasq.conf
		cat >> /etc/storage/dnsmasq/dnsmasq.conf << EOF
addn-hosts=/etc/storage/dnsmasq.ad/hosts
EOF
	else
		cat > /tmp/tmp_blacklist << EOF
## 自定义 hosts 设置
## 2019 by.lanse
127.0.0.1 localhost
::1 localhost
::1	ip6-localhost
::1	ip6-loopback
# 192.168.2.80    Boo
EOF
		grep -v '^!' $blacklist_storage | sed -E -e "/^#/d /^\s*$/d" -e "s:||:0.0.0.0 :" >> /tmp/tmp_blacklist
		mv -f /tmp/tmp_blacklist $ad_blacklistconf;  sleep 2
	fi
	ad_custom=$AD_HOME/ad_custom
	ad_customconf=$AD_HOME/ad_custom.conf
	custom_storage="/etc/storage/ad_custom.sh"
	if [ ! -f "$custom_storage" ] || [ ! -s "$custom_storage" ] ; then
		cp -f $ad_custom $custom_storage; chmod 644 $custom_storage
	else
		grep -v "^$" $custom_storage > $GZ_HOME/user.txt
	fi
	sed -Ei '/http/d' "$GZ_HOME/user.txt"
	echo @@\|http://\$domain=$(echo $ad_whitelistconf | tr , \|) >> "$GZ_HOME/user.txt"
}

add_hosts()
{
	hosts_ad=$(nvram get hosts_ad)
	tv_hosts=$(nvram get tv_hosts)
	nvram set adbyby_hostsad=0
	nvram set adbyby_tvbox=0
	[ ! -d "$HOSTS_HOME/hosts" ] && mkdir -p -m 755 $HOSTS_HOME/hosts
	if [ "$hosts_ad" = "1" ] ; then
		sed -i '/addn-hosts/d' /etc/storage/dnsmasq/dnsmasq.conf
		cat >> /etc/storage/dnsmasq/dnsmasq.conf << EOF
addn-hosts=/etc/storage/dnsmasq.ad/hosts
EOF
		wget -t 5 -T 10 -c --no-check-certificate -O- "https://raw.githubusercontent.com/vokins/yhosts/master/hosts" \
		| sed -e '/^\s*$/d; s/127.0.0.1/0.0.0.0/' > $HOSTS_HOME/hosts/hosts
		chmod 644 HOSTS_HOME/hosts/hosts; sleep 2
		if [ ! -f "$HOSTS_HOME/hosts/hosts" ] ; then
			sed -i '/addn-hosts/d' /etc/storage/dnsmasq/dnsmasq.conf
		else
			nvram set adbyby_hostsad=$(grep -v '^!' /etc/storage/dnsmasq.ad/hosts/hosts | wc -l)
		fi
	else
		sed -i '/addn-hosts/d' /etc/storage/dnsmasq/dnsmasq.conf
		rm -f $HOSTS_HOME/hosts/hosts
	fi
	if [ "$tv_hosts" = "1" ] ; then
		sed -i '/addn-hosts/d' /etc/storage/dnsmasq/dnsmasq.conf
		cat >> /etc/storage/dnsmasq/dnsmasq.conf << EOF
addn-hosts=/etc/storage/dnsmasq.ad/hosts
EOF
		wget --no-check-certificate -O- "https://dev.tencent.com/u/shaoxia1991/p/yhosts/git/raw/master/data/tvbox.txt" \
		| sed -e "s/127.0.0.1/0.0.0.0/" > $HOSTS_HOME/hosts/tvhosts
		chmod 644 $HOSTS_HOME/hosts/tvhosts; sleep 2
		if [ ! -f "$HOSTS_HOME/hosts/tvhosts" ] ; then
			sed -i '/addn-hosts/d' /etc/storage/dnsmasq/dnsmasq.conf
		else
			nvram set adbyby_tvbox=$(grep -v '^!' /etc/storage/dnsmasq.ad/hosts/tvhosts | wc -l)
		fi
	else
		sed -i '/addn-hosts/d' /etc/storage/dnsmasq/dnsmasq.conf
		rm -f $HOSTS_HOME/hosts/tvhosts
	fi
}

add_rules()
{
	if [ -f "/tmp/adb/bin/adupdate.sh" ] ; then
		sh /tmp/adb/bin/adupdate.sh
	else
		logger "adbyby" "正在检查规则是否需要更新!"
		rm -f $GZ_HOME/*.bak && sleep 2
		touch /tmp/local-md5.json && md5sum $GZ_HOME/lazy.txt $GZ_HOME/video.txt > /tmp/local-md5.json
		touch /tmp/md5.json && wget --no-check-certificate https://coding.net/u/adbyby/p/xwhyc-rules/git/raw/master/md5.json -O /tmp/md5.json

		lazy_local=$(grep 'lazy' /tmp/local-md5.json | awk -F' ' '{print $1}')
		video_local=$(grep 'video' /tmp/local-md5.json | awk -F' ' '{print $1}')
		lazy_online=$(sed  's/":"/\n/g' /tmp/md5.json  |  sed  's/","/\n/g' | sed -n '2p')
		video_online=$(sed  's/":"/\n/g' /tmp/md5.json  |  sed  's/","/\n/g' | sed -n '4p')

		if [ ! "$lazy_online"x = "$lazy_local"x -a  ! "$video_online"x = "$video_local"x ] ; then
			echo "MD5 not match! Need update!"
			logger "adbyby" "发现更新的规则,下载规则！"
			touch /tmp/lazy.txt && wget --no-check-certificate -t 1 -T 10 -O /tmp/lazy.txt https://coding.net/u/adbyby/p/xwhyc-rules/git/raw/master/lazy.txt
			touch /tmp/video.txt && wget --no-check-certificate -t 1 -T 10 -O /tmp/video.txt https://coding.net/u/adbyby/p/xwhyc-rules/git/raw/master/video.txt
			touch /tmp/local-md5.json && md5sum /tmp/lazy.txt /tmp/video.txt > /tmp/local-md5.json
			lazy_local=$(grep 'lazy' /tmp/local-md5.json | awk -F' ' '{print $1}')
			video_local=$(grep 'video' /tmp/local-md5.json | awk -F' ' '{print $1}')
			if [ "$lazy_online"x == "$lazy_local"x -a "$video_online"x == "$video_local"x ] ; then
				echo "New rules MD5 match!"
				mv -f /tmp/lazy.txt $GZ_HOME/lazy.txt && sleep 2
				mv -f /tmp/video.txt $GZ_HOME/video.txt
				echo $(date +%F) > /tmp/adbyby.updated
			fi
		else
			echo "MD5 match! No need to update!"
			logger "adbyby" "没有更新的规则,本次无需更新！"
		fi
		rm -f /tmp/lazy.txt /tmp/video.txt /tmp/local-md5.json /tmp/md5.json
		logger "adbyby" "Adbyby规则更新完成"
	fi
}

func_abp_up()
{
	/tmp/adb/bin/adblock.sh 2>&1 &
}

func_abp_mod()
{
	abp_mode=$(nvram get adbyby_adb_update)
	if [ ! -s "$AD_HOME/bin/dnsmasq.adblock" ] ; then
		func_abp_up
	else
		if [ "$wan_mode" = "1" ]
		then
			func_adblock_gz; sleep 3
		elif [ "$abp_mode" = "1" ]
		then
			func_adblock_gz; sleep 3
		else
			sed -i '/conf-file/d' /etc/storage/dnsmasq/dnsmasq.conf
			sed -i '/adblock.sh/d' /etc/storage/cron/crontabs/$http_username
			rm -f $HOSTS_HOME/dnsmasq.adblock
			nvram set adbyby_adb=0
		fi
	fi
}

func_adblock_gz()
{
	nvram set adbyby_adb=0
	if [ -f "$AD_HOME/bin/dnsmasq.adblock" ] ; then
		grep -q "adblock.sh" "/etc/storage/cron/crontabs/$http_username"
		if [ ! "$?" -eq "0" ]
		then
			sed -i '/adblock.sh/d' /etc/storage/cron/crontabs/$http_username
			sed -i '$a 45 5 * * * sh /tmp/adb/bin/adblock.sh > /dev/null 2>&1' /etc/storage/cron/crontabs/$http_username
		fi
	fi
	[ ! -d "$HOSTS_HOME" ] && mkdir -p -m 755 $HOSTS_HOME
	cp -f $AD_HOME/bin/dnsmasq.adblock $HOSTS_HOME/dnsmasq.adblock
	chmod 644 $HOSTS_HOME/dnsmasq.adblock
	nvram set adbyby_adb=$(grep -v '^!' /etc/storage/dnsmasq.ad/dnsmasq.adblock | wc -l)
	sed -i '/conf-file/d' /etc/storage/dnsmasq/dnsmasq.conf
	cat >> /etc/storage/dnsmasq/dnsmasq.conf << EOF
conf-file=/etc/storage/dnsmasq.ad/
EOF
	sleep 3 && logger "AD" "HOSTS 规则加载完成."
}

add_rule()
{
	if [ "$wan_mode" = "0" ]
	then
		port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
		if [ $port -eq 0 ]; then
			logger "添加 adbyby 透明代理端口 8118 !"
			iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8118
		fi

		if [ ! -n "$(pidof ad_watchcat)" ]
		then
			/tmp/adb/ad_watchcat >/dev/null 2>&1 &
			logger "Watchdog start up"
		fi
	else
		if [ -n "$(pidof ad_watchcat)" ]
		then
			kill -9 "$(pidof ad_watchcat)"
		fi
	fi
}

del_rule()
{
	grep -q "adbyby" "/etc/storage/cron/crontabs/$http_username"
	if [ "$?" -eq "0" ]
	then
		sed -i '/adbyby/d' /etc/storage/cron/crontabs/$http_username	
	fi
	grep -q "adblock.sh" "/etc/storage/cron/crontabs/$http_username"
	if [ "$?" -eq "0" ]
	then
		sed -i '/adblock.sh/d' /etc/storage/cron/crontabs/$http_username	
	fi
	grep -q "dnsmasq.ad" "/etc/storage/dnsmasq/dnsmasq.conf"
	if [ "$?" -eq "0" ]
	then
		sed -i '/conf-file/d /addn-hosts/d' /etc/storage/dnsmasq/dnsmasq.conf	
	fi
	port=$(iptables -t nat -L | grep 'ports 8118' | wc -l)
	if [[ "$port" -ge 1 ]] ; then
		logger "adbyby" "找到 $port 个 8118 透明代理端口,正在关闭..."
		iptables -t nat -D PREROUTING -p tcp --dport 80 -j REDIRECT --to-ports 8118
	fi
}

adbyby_start()
{
	if [ "$adbyby_enable" = "1" ] ; then
		del_rule
		if [ ! -f "$AD_HOME/bin/adbyby" ] ; then
			logger "adbyby" "adbyby程序文件不存在,正在解压..." && sleep 15
			tar -xzvf "/etc_ro/adbyby.tar.gz" -C "/tmp"
			logger "adbyby" "成功解压至:$AD_HOME"
		fi
		sed -i '/conf-file/d /addn-hosts/d' /etc/storage/dnsmasq/dnsmasq.conf
		add_cron && \
		sleep 3 && Black_white_list
		if [ "$wan_mode" = "0" ] ; then
			if [ ! -n "$(pidof adbyby)" ] ; then
				$AD_HOME/bin/adbyby &>/dev/null &
			fi
			add_rules
			add_rule
			sleep 3 && logger "adbyby" "Adbyby启动完成."
		elif [ "$wan_mode" = "1" ] ; then
			killall -q adbyby
			if [ -n "$(pidof ad_watchcat)" ] ; then
				kill -9 "$(pidof ad_watchcat)"
			fi
		fi
		add_hosts
		func_abp_mod && sleep 3; restart_dhcpd
	fi
}

adbyby_stop()
{
	if [ -n "$(pidof ad_watchcat)" ] ; then
		kill -9 "$(pidof ad_watchcat)"
	fi
	del_rule
	killall -q adbyby >/dev/null 2>&1
	if [ "$adbyby_enable" = "0" ] ; then
		nvram set adbyby_adb=$(grep -v '^!' /etc/storage/dnsmasq.ad/dnsmasq.adblock | wc -l)
		nvram set adbyby_hostsad=$(grep -v '^!' /etc/storage/dnsmasq.ad/hosts/hosts | wc -l)
		nvram set adbyby_tvbox=$(grep -v '^!' /etc/storage/dnsmasq.ad/hosts/tvhosts | wc -l)
		[ -f /var/log/adbyby_watchdog.log ] && rm -f /var/log/adbyby_watchdog.log
		rm -rf /tmp/adb
		rm -rf $HOSTS_HOME
		rm -f /tmp/adbyby.updated
	fi
	sleep 5 && logger "adbyby" "Adbyby已关闭."
	restart_dhcpd
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
