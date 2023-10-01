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

sudo mount -t proc proc $SCRIPTPATH/proc/
sudo mount -t sysfs sysfs $SCRIPTPATH/sys/
sudo mount -t devtmpfs udev $SCRIPTPATH/dev/
sudo mount -t devpts devpts $SCRIPTPATH/dev/pts/
sudo mount --rbind /tmp $SCRIPTPATH/tmp

echo "Mounting aarch64 paths"

mkdir $SCRIPTPATH/lib/aarch64-linux-gnu
touch $SCRIPTPATH/lib/ld-linux-aarch64.so.1
sudo mount --rbind /lib/ld-linux-aarch64.so.1 $SCRIPTPATH/lib/ld-linux-aarch64.so.1
sudo mount --rbind /lib/aarch64-linux-gnu $SCRIPTPATH/lib/aarch64-linux-gnu

# Overwrite the current rootfs because we're going in to a chroot
export FEX_ROOTFS=""

# Set the global config path to point to the explicit socket path
# Ensures that if the user changes that FEXServer still operates
export FEX_SERVERSOCKETPATH="/tmp/$(id -u)-$(basename $SCRIPTPATH).chroot"
mkdir -p $SCRIPTPATH/usr/share/fex-emu/Config/
echo "{\"Config\": {\"ServerSocketPath\":\"$FEX_SERVERSOCKETPATH\"}}" > $SCRIPTPATH/usr/share/fex-emu/Config.json
echo "FEX_SERVERSOCKETPATH=${FEX_SERVERSOCKETPATH}" >> $SCRIPTPATH/etc/environment

if command -v FEXServer>/dev/null; then
  echo "Starting FEXServer"
  # Start FEXServer with a 30 second timeout
  sudo --preserve-env=FEX_ROOTFS,FEX_SERVERSOCKETPATH FEXServer -p 30
fi

echo "Chrooting into container"
sudo --preserve-env=FEX_ROOTFS,FEX_SERVERSOCKETPATH chroot .

echo "Cleaning up chroot"
$SCRIPTPATH/break_chroot.sh
