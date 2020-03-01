<p align="center">
  <a href="https://travis-ci.com/896660689/rt-n56u">
    <img src="https://travis-ci.com/896660689/rt-n56u.svg?branch=k2x" alt="Build Status" />
  </a>
  <a href="https://github.com/896660689/rt-n56u/releases">
    <img src="https://img.shields.io/github/release/896660689/rt-n56u.svg?/all.svg?style=flat-square">
  </a>
</p>

# README #

Welcome to the rt-n56u project

This project aims to improve the rt-n56u and other supported devices on the software part, allowing power user to take full control over their hardware.
This project was created in hope to be useful, but comes without warranty or support. Installing it will probably void your warranty. 
Contributors of this project are not responsible for what happens next.

### How do I get set up? ###

* [Get the tools to build the system](https://bitbucket.org/padavan/rt-n56u/wiki/EN/HowToMakeFirmware) or [Download pre-built system image](https://bitbucket.org/padavan/rt-n56u/downloads)
* Feed the device with the system image file (Follow instructions of updating your current system)
* Perform factory reset
* Open web browser on http://my.router to configure the services

### Contribution guidelines ###

* To be completed

***

- 已适配除官方适配外的以下机型

>- K2_256_USB (256M)
>- K2P/K2P_5.3 (128M)


### 编译说明 ###

* 安装依赖包
```shell
sudo apt update
sudo apt install unzip libtool-bin curl cmake gperf gawk flex bison nano xxd \
cpio git python-docutils gettext automake autopoint texinfo build-essential help2man \
```
* 克隆源码
```shell
git clone --depth=1 https://gitee.com/896660689/rt-n56u.git /opt/rt-n56u
#git clone --depth=1 https://github.com/896660689/rt-n56u.git /opt/rt-n56u
```
* 准备工具链
```shell
cd /opt/rt-n56u/toolchain-mipsel
<<<<<<< HEAD
./clean_toolchain
./build_toolchain
=======

# 可以从源码编译工具链，这需要一些时间：
# Manjaro/ArchLinux用户请使用gcc-8
./clean_toolchain
./build_toolchain

# 或者下载预编译的工具链：
mkdir -p toolchain-3.4.x
wget https://github.com/hanwckf/padavan-toolchain/releases/download/v1.1/mipsel-linux-uclibc.tar.xz
tar -xvf mipsel-linux-uclibc.tar.xz -C toolchain-3.4.x
>>>>>>> 6ea98e38a30400393b18e8f7b3a316c524eb3021
```
* (可选) 修改机型配置文件
```shell
nano /opt/rt-n56u/trunk/configs/templates/PSG1218.config
```
* 清理代码树并开始编译
```shell
cd /opt/rt-n56u/trunk
sudo ./clear_tree
sudo ./build_firmware_modify k2
# 脚本第一个参数为路由型号，在trunk/configs/templates/中
# 编译好的固件在trunk/images里
```

