#!/bin/bash -e

dist_version="crimson"
dist_name="deepin"

TARGET_ROOTFS_DIR=./rootfs/$dist_name-$dist_version

sudo cp -b /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf
#sudo cp -b /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
sudo cp -rpf ./packages $TARGET_ROOTFS_DIR/

echo -e "\033[47;36m Change root.................... \033[0m"

sudo mount -t proc /proc $TARGET_ROOTFS_DIR/proc
sudo mount -t sysfs /sys $TARGET_ROOTFS_DIR/sys
sudo mount -o bind /dev $TARGET_ROOTFS_DIR/dev

sudo mount -t tmpfs -o "size=99%" tmpfs "$TARGET_ROOTFS_DIR/tmp"
sudo mount -t tmpfs -o "size=99%" tmpfs "$TARGET_ROOTFS_DIR/var/tmp"


cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR/

export DEBIAN_FRONTEND=noninteractive

apt -y update

export APT_INSTALL="apt install -fy --allow-downgrades"

dpkg -i /packages/boot/*.deb

\${APT_INSTALL} deepin-desktop-environment-core \
        deepin-desktop-environment-base \
        deepin-desktop-environment-cli \
        deepin-desktop-environment-extras \
        firefox \
        fastfetch \
        gparted

systemctl enable lightdm

\${APT_INSTALL} /packages/*.deb
\${APT_INSTALL} /packages/rga2/*.deb
\${APT_INSTALL} /packages/mpp/*.deb
\${APT_INSTALL} /packages/gst-rkmpp/*.deb

HOST=darkmoon

# Create User
useradd -G sudo -m -s /bin/bash darkmoon
passwd darkmoon <<IEOF
darkmoon
darkmoon
IEOF
gpasswd -a darkmoon video
gpasswd -a darkmoon audio
passwd root <<IEOF
root
root
IEOF

echo "darkmoon  ALL=(ALL:ALL) ALL" >> /etc/sudoers

# hostname
echo darkmoon > /etc/hostname

# set localtime
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

dpkg-reconfigure locales

apt-get clean
rm -rf /packages/

history -c

EOF

 
sudo umount $TARGET_ROOTFS_DIR/tmp
sudo umount $TARGET_ROOTFS_DIR/var/tmp
sudo umount $TARGET_ROOTFS_DIR/proc
sudo umount $TARGET_ROOTFS_DIR/sys
sudo umount $TARGET_ROOTFS_DIR/dev

sudo tar -zcf $dist_name-$dist_version-rootfs-arm64.tar.gz -C $TARGET_ROOTFS_DIR .
sudo split -b 1900M  $dist_name-$dist_version-rootfs-arm64.tar.gz -d -a 2 rootfs_

