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
rmdir "$BACKUPPATH/etc"

echo "Moving rootfs folders back to original location"
# Move back folders that we removed
mv "$BACKUPPATH/boot" "$SCRIPTPATH"
mv "$BACKUPPATH/home" "$SCRIPTPATH"
mv "$BACKUPPATH/media" "$SCRIPTPATH"
mv "$BACKUPPATH/mnt" "$SCRIPTPATH"
rsync -a "$BACKUPPATH/root" "$SCRIPTPATH"
rm -Rf "$BACKUPPATH/root"
mv "$BACKUPPATH/srv" "$SCRIPTPATH"
mv "$BACKUPPATH/tmp" "$SCRIPTPATH"
mv "$BACKUPPATH/opt" "$SCRIPTPATH"

echo "Moving rootfs apt folders back to original location"
mv "$BACKUPPATH/var/cache/apt" "$SCRIPTPATH/var/cache/"
mv "$BACKUPPATH/var/lib/apt" "$SCRIPTPATH/var/lib/"

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
sudo mount -t proc /proc $SCRIPTPATH/proc/
sudo mount --rbind --make-rslave /sys $SCRIPTPATH/sys/
sudo mount --rbind --make-rslave /dev $SCRIPTPATH/dev/
sudo mount --rbind --make-rslave /dev/pts $SCRIPTPATH/dev/pts/

echo "Mounting aarch64 paths"

mkdir $SCRIPTPATH/lib/aarch64-linux-gnu
touch $SCRIPTPATH/lib/ld-linux-aarch64.so.1
sudo mount --rbind /lib/ld-linux-aarch64.so.1 $SCRIPTPATH/lib/ld-linux-aarch64.so.1
sudo mount --rbind /lib/aarch64-linux-gnu $SCRIPTPATH/lib/aarch64-linux-gnu

echo "Chrooting into container"
echo "!!! Make sure to execute break_chroot.sh after leaving !!!"
sudo chroot .
