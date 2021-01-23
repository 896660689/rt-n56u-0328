#!/bin/sh
## Adaptation Grassland in Lucheng 2020.05.03

tmpdir="/tmp/adbyby/ad"
TMP_HOME="/tmp/adbyby/bin"
logger_title="[Adbyby]"

restart_ad(){
	/usr/bin/adbyby.sh start
}

rm_cache(){
    rm -rf $tmpdir
    rm -f $TMP_HOME/data/*.bak
}

judge_update(){
    if [ "$lazy_online"x == "$lazy_local"x ]; then
        logger -t "${logger_title}" "本地 lazy 规则已经最新，无需更新"
        if [ "$video_online"x == "$video_local"x ]; then
            logger -t "${logger_title}" "本地 video 规则已经最新，无需更新"
        else
            logger -t "${logger_title}" "检测到 video 规则更新，下载规则中..."
            download_video;restart_ad
        fi
    else
        logger -t "${logger_title}" "检测到 lazy 规则更新，下载规则中..."
        if [ "$video_online"x == "$video_local"x ]; then
            logger -t "${logger_title}" "本地 video 规则已经最新，无需更新"
            download_lazy;restart_ad
        else
            logger -t "${logger_title}" "检测到 video 规则更新，下载规则中..."
            download_lazy;download_video;restart_ad
        fi
    fi
    sleep 2 && rm_cache && exit 0
}

download_lazy(){
    wget -q -c -P $tmpdir 'https://adbyby.coding.net/p/xwhyc-rules/d/xwhyc-rules/git/raw/master/lazy.txt'
    if [ "$?"x != "0"x ]; then
        logger -t "${logger_title}" "【lazy】下载coding中的规则失败，尝试下载github中的规则"
        wget -q -c -P $tmpdir 'https://raw.githubusercontent.com/adbyby/xwhyc-rules/master/lazy.txt'
        if [ "$?"x != "0"x ]; then
            logger -t "${logger_title}" "【lazy】双双失败GG，请检查网络"
        else
            mv $tmpdir/lazy.txt $TMP_HOME/data/lazy.txt
            logger -t "${logger_title}" "【lazy】下载成功，更新完成..."
        fi
    else
        mv $tmpdir/lazy.txt $TMP_HOME/data/lazy.txt
        logger -t "${logger_title}" "【lazy】下载成功，更新完成..."
    fi
}

download_video(){
    wget -q -c -P $tmpdir 'https://adbyby.coding.net/p/xwhyc-rules/d/xwhyc-rules/git/raw/master/video.txt'
    if [ "$?"x != "0"x ]; then
        logger -t "${logger_title}" "【video】下载coding中的规则失败，尝试下载github中的规则"
        wget -q -c -P $tmpdir 'https://raw.githubusercontent.com/adbyby/xwhyc-rules/master/video.txt'
        if [ "$?"x != "0"x ]; then
            logger -t "${logger_title}" "【video】双双失败GG，请检查网络"
        else
            mv $tmpdir/video.txt $TMP_HOME/data/video.txt
            logger -t "${logger_title}" "【video】下载成功，更新完成..."
        fi
    else
        mv $tmpdir/video.txt $TMP_HOME/data/video.txt
        logger -t "${logger_title}" "【video】下载成功，更新完成..."
    fi
}

# check_rules()
    rm_cache
    mkdir $tmpdir
    logger -t "${logger_title}" "自动检测规则更新中" && cd $tmpdir
    md5sum $TMP_HOME/data/lazy.txt $TMP_HOME/data/video.txt > local-md5.json
    wget -q -c -P $tmpdir 'https://adbyby.coding.net/p/xwhyc-rules/git/raw/master/md5.json'
    if [ "$?"x != "0"x ]; then
        logger -t "${logger_title}" "获取在线规则时间失败" && exit 0
    else
        lazy_local=$(grep 'lazy' local-md5.json | awk -F' ' '{print $1}')
        video_local=$(grep 'video' local-md5.json | awk -F' ' '{print $1}')
        lazy_online=$(sed  's/":"/\n/g' md5.json  |  sed  's/","/\n/g' | sed -n '2p')
        video_online=$(sed  's/":"/\n/g' md5.json  |  sed  's/","/\n/g' | sed -n '4p')
        logger -t "${logger_title}"  "获取在线规则 MD5 成功，正在判断是否有更新中"
        #sed -i "s/=video,lazy/=none/g" $TMP_HOME/adhook.ini
        #sed -i "s/=video,lazy/=none/g" $TMP_HOME/adhook.sample.ini
        judge_update
    fi
    rm -rf $tmpdir
    exit 0
