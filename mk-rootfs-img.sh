#!/bin/bash -e

dist_version="crimson"
dist_name="deepin"

TARGET_ROOTFS_DIR=./rootfs/$dist_name-$dist_version
ROOTFSIMAGE=$dist_name-$dist_version-arm64-rootfs.img

echo Making rootfs!

if [ -e ${ROOTFSIMAGE} ]; then
	rm ${ROOTFSIMAGE}
fi


sudo cp -rpf overlay/* $TARGET_ROOTFS_DIR/

IMAGE_SIZE_MB=$(( $(sudo du -sh -m ${TARGET_ROOTFS_DIR} | cut -f1) ))

# Extra 10%
IMAGE_SIZE_MB=$(( $IMAGE_SIZE_MB * 110 / 100 ))

dd if=/dev/zero of=${ROOTFSIMAGE} bs=1M count=0 seek=${IMAGE_SIZE_MB}

sudo mkfs.ext4 -d ${TARGET_ROOTFS_DIR} ${ROOTFSIMAGE}

echo Rootfs Image: ${ROOTFSIMAGE}
