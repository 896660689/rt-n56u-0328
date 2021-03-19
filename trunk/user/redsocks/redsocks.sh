#!/bin/bash
# Github: https://github.com/SuzukiHonoka

BINARY_NAME="redsocks"
BIN_DIR="/usr/bin"
STORAGE="/etc/storage"
BINARY_PATH="$BIN_DIR/$BINARY_NAME"
REDSOCKS_DIR="$STORAGE/$BINARY_NAME"
REDSOCKS_CONF="$REDSOCKS_DIR/$BINARY_NAME.conf"
CHAIN_NAME="REDSOCKS"
dir_chnroute_file="$STORAGE/chinadns/chnroute.txt"
LOCK="/tmp/set_lock"
SET_NAME="china"
MODE=false

SOCKS5_IP=$(nvram get dhcp_end)
SOCKS5_PORT=$(nvram get ss_local_port)
REMOTE_IP="127.0.0.1"

ARG1=$1
ARG2=$2
ARG3=$3

func_redsocks(){
cd $REDSOCKS_DIR
$BINARY_PATH $REDSOCKS_CONF
}

func_save(){
/sbin/mtd_storage.sh save
}

func_start(){
MODE=true
if [ -n "$(pidof redsocks)" ]
then
func_stop
logger -t $BINARY_NAME "ALREADY RUNNING: KILLED"
fi
if [ ! -f $REDSOCKS_CONF ]
then
if  [ -n "$ARG2" ]
then
if [ -n "$ARG3" ]
then
SOCKS5_IP=$ARG2
SOCKS5_PORT=$ARG3
[ ! -d "$REDSOCKS_DIR" ] && mkdir -p "$REDSOCKS_DIR"
cat > "$REDSOCKS_CONF" <<EOF
base {
log_debug = off;
log_info = off;
redirector = iptables;
daemon = on;
redsocks_conn_max = 10000;
rlimit_nofile = 10240;
}

redsocks {
local_ip = 0.0.0.0;
local_port = 12345;
ip = $(nvram get dhcp_end);
port = $(nvram get ss_local_port);
type = socks5;
}
EOF
chmod 644 $REDSOCKS_CONF
logger -t $BINARY_NAME "CONFIG FILE SAVED."
func_redsocks
fi
else
logger -t $BINARY_NAME "CONFIG FILE NOT FOUND"
return 0
fi
else
func_redsocks
logger -t $BINARY_NAME "STARTED."
fi
}

func_clean(){
iptables-save -c | grep -v $CHAIN_NAME | iptables-restore -c && sleep 2
ipset -X $SET_NAME >/dev/null 2>&1 &
}

func_iptables(){
if [ -n "$ARG2" ]
then
REMOTE_IP=$ARG2
else
logger -t $BINARY_NAME "$REMOTE_IP NOT FOUND!"
return 0
fi
func_clean
if [ ! -f "$dir_chnroute_file" ] || [ ! -s "$dir_chnroute_file" ]
then
[ ! -d $STORAGE/chinadns ] && mkdir -p "$STORAGE/chinadns"
tar jxf "/etc_ro/chnroute.bz2" -C "$STORAGE/chinadns"
chmod 644 "$dir_chnroute_file" && sleep 2
fi
if [ -f "$dir_chnroute_file" ] || [ -s "$dir_chnroute_file" ]
then
ipset -N china hash:net
#for i in $(cat $dir_chnroute_file ); do ipset -A china $i; done
awk '!/^$/&&!/^#/{printf("add china %s'" "'\n",$0)}' $dir_chnroute_file | ipset restore && \
wait
echo "load ip rules !"
fi
[ ! -f $LOCK ] && touch $LOCK && logger -t $BINARY_NAME "SET LOCKED"

iptables -t nat -N $CHAIN_NAME
iptables -t nat -A $CHAIN_NAME -d $REMOTE_IP -j RETURN
iptables -t nat -A $CHAIN_NAME -d 0.0.0.0/8 -j RETURN
iptables -t nat -A $CHAIN_NAME -d 10.0.0.0/8 -j RETURN
iptables -t nat -A $CHAIN_NAME -d 127.0.0.0/8 -j RETURN
iptables -t nat -A $CHAIN_NAME -d 169.254.0.0/16 -j RETURN
iptables -t nat -A $CHAIN_NAME -d 172.16.0.0/12 -j RETURN
iptables -t nat -A $CHAIN_NAME -d 192.168.0.0/16 -j RETURN
iptables -t nat -A $CHAIN_NAME -d 224.0.0.0/4 -j RETURN
iptables -t nat -A $CHAIN_NAME -d 240.0.0.0/4 -j RETURN
iptables -t nat -A $CHAIN_NAME -m set --match-set china dst -j RETURN
iptables -t nat -A $CHAIN_NAME -p tcp -j REDIRECT --to-ports 12345
iptables -t nat -A PREROUTING -p tcp -j $CHAIN_NAME
iptables -t nat -A OUTPUT -p tcp -j $CHAIN_NAME
}

func_stop(){
if [ -n "$(pidof $BINARY_NAME)" ] ; then
killall $BINARY_NAME
sleep 2
fi
func_clean
[ -d "$REDSOCKS_DIR" ] && rm -rf "$REDSOCKS_DIR"
logger -t $BINARY_NAME "KILLED"
}

case "$ARG1" in
start)
func_start
;;
stop)
func_stop
;;
iptables)
func_iptables
;;
clean)
func_clean
;;
restart)
func_stop
func_start
;;
*)
echo "Usage: $0 { start [ $1 IP $2 PORT $3 IP ] | stop | iptables [ $1 IP ] | restart }"
exit 1
;;
esac

