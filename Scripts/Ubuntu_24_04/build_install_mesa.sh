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
apt-get install -y libgl1 libgl1:i386 mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers libglx-mesa0 libgl1-mesa-dri \
    libegl-mesa0

apt-get upgrade -y

apt-mark hold \
  libegl-mesa0 libegl-mesa0:i386 libgbm1 libgbm1:i386 libgl1-mesa-dri \
  libgl1-mesa-dri:i386 libglx-mesa0 libglx-mesa0:i386 libllvm20 libllvm20:i386 \
  mesa-libgallium mesa-libgallium:i386 mesa-va-drivers mesa-va-drivers:i386 \
  mesa-vdpau-drivers mesa-vdpau-drivers:i386 mesa-vulkan-drivers \
  mesa-vulkan-drivers:i386
