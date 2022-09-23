#!/bin/sh

# Add source packages
sed -i -e "s/^# deb/deb/g" /etc/apt/sources.list
apt-get update

cd /root
export DEBIAN_FRONTEND=noninteractive

apt-get install -y software-properties-common
# Add kisak-ppa to get newer LLVM
add-apt-repository -y ppa:kisak/kisak-mesa

apt-get upgrade -y
apt-get install -y mesa-va-drivers mesa-vdpau-drivers mesa-vulkan-drivers libglx-mesa0 libgles2-mesa libgl1-mesa-glx libgl1-mesa-dri libegl1-mesa \
	libegl-mesa0
