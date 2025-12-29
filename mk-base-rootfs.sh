#!/bin/bash

set -e -u -x

sudo apt update

# 不进行交互安装
export DEBIAN_FRONTEND=noninteractive
#ROOTFS=`mktemp -d`
# deepin 25版本代号

dist_version="crimson"
dist_name="deepin"
SOURCES_FILE=config/apt/sources.list
PACKAGES_FILE=config/packages.list/packages.list
readarray -t REPOS < $SOURCES_FILE
PACKAGES=`cat $PACKAGES_FILE | grep -v "^-" | xargs | sed -e 's/ /,/g'`

OUT_DIR=rootfs
ROOTFS=$OUT_DIR/$dist_name-$dist_version

mkdir -p $OUT_DIR
mkdir -p $ROOTFS
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 425956BB3E31DF51
sudo apt update -y && sudo apt install -y curl git mmdebstrap qemu-user-static systemd-container
# 开启异架构支持
sudo systemctl start systemd-binfmt

sudo mmdebstrap  \
	--hook-dir=/usr/share/mmdebstrap/hooks/merged-usr \
	--include=$PACKAGES \
	--components="main,commercial,community" \
	--variant=minbase \
	--architectures=arm64 \
	--customize=./config/hooks.chroot/second-stage \
	$dist_version \
	$ROOTFS \
	"${REPOS[@]}"
	
# 生成压缩包

#rm -rf $dist_name-$dist_version-rootfs-$arch.tar.gz
sudo tar -zcf $dist_name-$dist_version-rootfs-arm64.tar.gz -C $ROOTFS .
# 删除临时文件夹
#sudo rm -rf  $ROOTFS



