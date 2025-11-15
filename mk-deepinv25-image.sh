#!/bin/bash
# create_rockchip_image.sh

set -e

dist_version="crimson"
dist_name="deepin"

MOUNTPATH="./mountpath"
IMAGE="$dist_name-$dist_version-arm64.img"
UBOOT_BIN="u-boot.bin"
ROOTFS_DIR="./rootfs/$dist_name-$dist_version"
ROOT_UUID="9ea2a464-a80c-46a0-85a4-7f2f6b81f662"

sudo cp -rpf overlay/* $ROOTFS_DIR/


if [ -e ${IMAGE} ]; then
	rm ${IMAGE}
fi

if [ -e ${MOUNTPATH} ]; then
	rm -rf ${MOUNTPATH}
fi

mkdir ${MOUNTPATH}
echo "Making rootfs!"

IMAGE_SIZE_MB=$(( $(sudo du -sh -m ${ROOTFS_DIR} | cut -f1) ))

# Extra 10%
IMAGE_SIZE_MB=$(( $IMAGE_SIZE_MB * 110 / 100 + 100))

dd if=/dev/zero of=${IMAGE} bs=1M count=0 seek=${IMAGE_SIZE_MB}

echo "write U-Boot..."
dd if="$UBOOT_BIN" of="$IMAGE" bs=512 seek=64 conv=notrunc,fsync

echo "creat rootfs partition..."
parted --script "$IMAGE" \
    mklabel gpt \
    mkpart primary ext4 16M 100%

sudo kpartx -av "$IMAGE"
sleep 2

LOOP_DEVICE=$(losetup -a | grep "$IMAGE" | cut -d: -f1 | sort -rV | head -1 | xargs basename)

sudo mkfs.ext4 -U "$ROOT_UUID" -L "root" "/dev/mapper/${LOOP_DEVICE}p1"

echo "copy rootfs..."
sudo mount "/dev/mapper/${LOOP_DEVICE}p1" ${MOUNTPATH}
sudo rsync -a "$ROOTFS_DIR"/ ${MOUNTPATH}

sudo umount /dev/mapper/${LOOP_DEVICE}p1
sudo kpartx -dv "/dev/${LOOP_DEVICE}"

echo "Creat img successful: $IMAGE"
