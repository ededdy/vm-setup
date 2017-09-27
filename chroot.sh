#!/bin/bash

set -x
PASSWORD=root

# We bindmount /dev /sys /proc which is needed by apt to install our
# dependencies.
mount -t proc none /proc
mount -t sysfs none /sys

# Set locale for apt.
locale-gen
export LC_ALL=C

# Set root password.
echo "root:$PASSWORD" | chpasswd
hostname valilla-vm

#Dependencies/Utilities for the system.
INSTALL_PKGS="git strace openssh-server "

# Dependencies for user-space tools.
INSTALL_PKGS=$INSTALL_PKGS"autoconf automake libtool libtool-bin pkg-config "

# Dependencies for xfstests.
INSTALL_PKGS=$INSTALL_PKGS"uuid-dev xfsprogs xfslibs-dev libattr1-dev libacl1-dev "
for i in ${INSTALL_PKGS}; do
        echo "Installing $i ..."
        apt-get install -y "${i%% *}" 2>&- || {
                echo >&2 "Installing '${i%% *}' failed. Aborting."
                break
        }
done

# Allow ssh into root.
sed -i.bak  s/"PermitRootLogin prohibit-password"/"PermitRootLogin yes"/ etc/ssh/sshd_config

# We are now done with the minimum setup for the root image which we can now
# boot into through qemu.
umount /sys
umount /proc
umount /dev
