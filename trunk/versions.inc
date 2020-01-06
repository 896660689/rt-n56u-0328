FIRMWARE_ROOTFS_VER=3.9
FIRMWARE_BUILDS_VER=$(shell date +%m%d 2>/dev/null)
FIRMWARE_BUILDS_REV=$(shell git rev-parse --short=7 HEAD 2>/dev/null)
