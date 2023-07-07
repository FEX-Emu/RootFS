#!/bin/sh

# Usage:
# cd in to the rootfs directory
# sh ./break_chroot.sh
# You will be asked for your root password to unmount the mounts

# Get script path
SCRIPTPATH="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
BACKUPPATH="$SCRIPTPATH/chroot/"

# Make the backup path
mkdir "$BACKUPPATH"

# Unmount and delete mount points
echo "Unmounting container mounts"

umount -R "$SCRIPTPATH/tmp"
umount "$SCRIPTPATH/proc/"
umount -R "$SCRIPTPATH/sys/"
umount -R "$SCRIPTPATH/dev/pts/"
umount -R "$SCRIPTPATH/dev/"

echo "Removing container mount folders"
rmdir "$SCRIPTPATH/sys"
rmdir "$SCRIPTPATH/dev/pts/"
rmdir "$SCRIPTPATH/dev"
rmdir "$SCRIPTPATH/proc"

# Remove FEXConfig directory
rm -Rf $SCRIPTPATH/usr/share/fex-emu

# Move files from etc that we need to remove
echo "Backing up chroot files"
mkdir -p "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/hosts" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/resolv.conf" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/timezone" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/localtime" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/passwd" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/passwd-" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/group" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/group-" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/shadow" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/shadow-" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/gshadow" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/gshadow-" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/fstab" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/mtab" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/subuid" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/subgid" "$BACKUPPATH/etc/"
mv "$SCRIPTPATH/etc/machine-id" "$BACKUPPATH/etc/"

# Move various folders
mv "$SCRIPTPATH/boot" "$BACKUPPATH"
mv "$SCRIPTPATH/home" "$BACKUPPATH"
mv "$SCRIPTPATH/media" "$BACKUPPATH"
mv "$SCRIPTPATH/mnt" "$BACKUPPATH"
mv "$SCRIPTPATH/root" "$BACKUPPATH"
mv "$SCRIPTPATH/srv" "$BACKUPPATH"
mv "$SCRIPTPATH/tmp" "$BACKUPPATH"
mv "$SCRIPTPATH/run" "$BACKUPPATH"

# Only move opt if it is empty
[ "$(ls -A $SCRIPTPATH/opt)" ] && true || mv "$SCRIPTPATH/opt" "$BACKUPPATH"

mkdir -p "$BACKUPPATH/var/cache/"
mkdir -p "$BACKUPPATH/var/lib/"
mkdir -p "$BACKUPPATH/var/lib/dbus/"

mv "$SCRIPTPATH/var/tmp" "$BACKUPPATH/var/"
mv "$SCRIPTPATH/var/run" "$BACKUPPATH/var/"
mv "$SCRIPTPATH/var/lock" "$BACKUPPATH/var/"
mv "$SCRIPTPATH/var/lib/dbus/machine-id" "$BACKUPPATH/var/lib/dbus/"

# If user was tinkering the the chroot then likely there are things that are set to root ownership
# Change ownership to fix this
# Explicitly avoiding the mount folders. Avoids warning from dangling mounts.
echo "Fixing any potential permission issues"
chown -R $USER:$GROUP "$SCRIPTPATH/bin"
chown -R $USER:$GROUP "$SCRIPTPATH/chroot"
chown -R $USER:$GROUP "$SCRIPTPATH/etc"
chown -R $USER:$GROUP "$SCRIPTPATH/lib"
chown -R $USER:$GROUP "$SCRIPTPATH/lib64"
chown -R $USER:$GROUP "$SCRIPTPATH/sbin"
chown -R $USER:$GROUP "$SCRIPTPATH/usr"
chown -R $USER:$GROUP "$SCRIPTPATH/var"
