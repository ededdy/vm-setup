#!/bin/bash
#
# Setting up a virtual machine instance with qemu-kvm running vanilla kernel
# and a minimal Ubuntu userspace.
#
# Step 1 (Prepare disk images):
# Use this rudimentary script to prepare the root image for a ubuntu userspace
# which we can boot to using qemu.  We use a custom vanilla kernel underneath
# and we use this user-space to have our favourite tools to hack the custom
# kernel.  Then after we have prepared the disk images we can boot into it with
# the following command (below).
#
# Step 2 (Configure and build min config vanilla kernel):
# 1) mkdir kernel
# 2) cd kernel && git clone git://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git
# 3) cd linux
# 4) make x86_64_defconfig
# 5) make kvmconfig
# 6) make -j 8
#
# Step 3 (Boot with qemu):
# qemu-system-x86_64 -smp 2 -m 4G -kernel kernel/linux/arch/x86_64/boot/bzImage
# -drive file=ubuntu-xenial.raw,index=0,media=disk,format=raw
# -drive file=disk1.raw,if=ide,index=1,cache=writeback,media=disk,format=raw
# -drive file=disk2.raw,if=ide,index=2,cache=writeback,media=disk,format=raw
# -drive file=disk3.raw,if=ide,index=3,cache=writeback,media=disk,format=raw
# -append "ip=dhcp root=/dev/sda console=ttyS0" -netdev user,id=user.0 -device
# e1000,netdev=user.0 -redir tcp:2222::22 --enable-kvm --nographic
#
# Author: Sougata Santra <sougata.santra@gmail.com>

set -uex

RELEASE=$(cat /etc/lsb-release | grep DISTRIB_CODENAME | cut -d "=" -f 2)
IMAGE_SIZE=10G
ROOT_IMAGE_NAME=ubuntu-${RELEASE}.raw
VOLUME_NAME=disk1.raw
VOLUME1_NAME=disk2.raw
VOLUME2_NAME=disk3.raw
MOUNT_POINT=tmp_mount
ARCH=amd64

if [ $(id -u) -ne 0 ]; then
	echo >&2 "Running $0 requires root privilege."
	exit 1
fi

DEPENDENCIES="qemu-img debootstrap apt-get mkfs.ext4"
for i in ${DEPENDENCIES}; do
	which "${i%% *}" 2>&- || {
		echo >&2 "Required '${i%% *}' but it's not installed. Aborting."
		exit 1
	}
done

# We prepare a root volume '/dev/sda' and three other volumes, all attached to
# IDE interface. Of there three additional volumes one is used to hold any
# binary or source utilities which we compile and scp from host and the
# other two are used for test and scratch for xfstest etc. Or any runtime tests.
#
qemu-img create -f raw $ROOT_IMAGE_NAME $IMAGE_SIZE
qemu-img create -f raw $VOLUME_NAME $IMAGE_SIZE
qemu-img create -f raw $VOLUME1_NAME $IMAGE_SIZE
qemu-img create -f raw $VOLUME2_NAME $IMAGE_SIZE
mkdir $MOUNT_POINT
mkfs.ext4 $ROOT_IMAGE_NAME
mount -t ext4 $ROOT_IMAGE_NAME $MOUNT_POINT
debootstrap --arch $ARCH $RELEASE $MOUNT_POINT
cp chroot.sh $MOUNT_POINT/
mount --bind /dev/ $MOUNT_POINT/dev/
LANG=C chroot $MOUNT_POINT ./chroot.sh
umount $MOUNT_POINT
rm -rf $MOUNT_POINT
