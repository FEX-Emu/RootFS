#!/bin/sh

# Add source packages
sed -i -e "s/^Types: deb/Types: deb deb-src/g" /etc/apt/sources.list.d/ubuntu.sources
apt-get update

cd /root
export DEBIAN_FRONTEND=noninteractive
dpkg --add-architecture i386

apt-get install -y software-properties-common

# Just use kisk-ppa
# Debian/Ubuntu llvm development packages have been broken for multiple releases.
add-apt-repository -y ppa:kisak/kisak-mesa

apt-get update
apt-get upgrade -y
apt-get install -y mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers libglx-mesa0 libgles2-mesa libgl1-mesa-glx libgl1-mesa-dri libegl1-mesa \
    libegl-mesa0 pulseaudio libgles1 libgles21 mesa-utils mesa-utils-extra libgl1
apt-get upgrade -y
