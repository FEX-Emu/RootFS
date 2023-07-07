#!/bin/sh

# Usage:
# cd in to the rootfs directory
# sh ./unbreak_chroot.sh
# You will be prompted for your password to mount container paths
# At the end you should be inside the chroot

# Get script path
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
BACKUPPATH="$SCRIPTPATH/chroot/"

echo "Moving rootfs files back to original location"
# Move back files that we removed
mv "$BACKUPPATH/etc/hosts" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/resolv.conf" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/timezone" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/localtime" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/passwd" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/passwd-" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/group" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/group-" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/shadow" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/shadow-" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/gshadow" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/gshadow-" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/fstab" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/hostname" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/mtab" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/subuid" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/subgid" "$SCRIPTPATH/etc/"
mv "$BACKUPPATH/etc/machine-id" "$SCRIPTPATH/etc/"

rmdir "$BACKUPPATH/etc"

echo "Moving rootfs folders back to original location"
# Move back folders that we removed
mv "$BACKUPPATH/boot" "$SCRIPTPATH"
mv "$BACKUPPATH/home" "$SCRIPTPATH"
mv "$BACKUPPATH/media" "$SCRIPTPATH"
mv "$BACKUPPATH/mnt" "$SCRIPTPATH"
mv "$BACKUPPATH/root" "$SCRIPTPATH"
mv "$BACKUPPATH/srv" "$SCRIPTPATH"
mv "$BACKUPPATH/tmp" "$SCRIPTPATH"
mv "$BACKUPPATH/run" "$SCRIPTPATH"

# Only move opt if it is empty
[ "$(ls -A $BACKUPPATH/opt)" ] && true || mv "$BACKUPPATH/opt" "$SCRIPTPATH"

echo "Moving rootfs folders back to original location"
mv "$BACKUPPATH/var/lib/dbus" "$SCRIPTPATH/var/lib/"
mv "$BACKUPPATH/var/tmp" "$SCRIPTPATH/var/"
mv "$BACKUPPATH/var/run" "$SCRIPTPATH/var/"
mv "$BACKUPPATH/var/lock" "$SCRIPTPATH/var/"

rmdir "$BACKUPPATH/var/cache/"
rmdir "$BACKUPPATH/var/lib/"
rmdir "$BACKUPPATH/var"

rmdir "$BACKUPPATH"

echo "Changing rootfs permissions on /tmp"
# For some reason /tmp ends up being 0664
chmod 1777 "$SCRIPTPATH/tmp"

# Create and mount folders
mkdir "$SCRIPTPATH/sys"
mkdir "$SCRIPTPATH/dev"
mkdir "$SCRIPTPATH/dev/pts"
mkdir "$SCRIPTPATH/proc"

echo "Mounting rootfs paths"

mount -t proc proc $SCRIPTPATH/proc/
mount -t sysfs sysfs $SCRIPTPATH/sys/
mount -t devtmpfs udev $SCRIPTPATH/dev/
mount -t devpts devpts $SCRIPTPATH/dev/pts/
mount --rbind /tmp $SCRIPTPATH/tmp

echo "Chrooting into container"
chroot .

echo "Cleaning up chroot"
$SCRIPTPATH/break_chroot.sh
