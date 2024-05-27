#!/bin/sh

# Move to /root/
cd /root

export DEBIAN_FRONTEND=noninteractive
apt-get install -y \
	git \
	build-essential \
	libx11-xcb-dev \
	libxcb-keysyms1-dev \
	libwayland-dev \
	libxrandr-dev \
	zlib1g-dev \
	liblz4-dev \
	libzstd-dev \
	libx11-xcb-dev:i386 \
	libxcb-keysyms1-dev:i386 \
	libwayland-dev:i386 \
	libxrandr-dev:i386 \
	zlib1g-dev:i386 \
	liblz4-dev:i386 \
	libzstd-dev:i386 \
	g++ \
	libvulkan-dev \
  libstdc++-13-dev-i386-cross \
  libgcc-13-dev-i386-cross \
	cmake

apt-get install -y g++-multilib gcc-multilib

git clone --depth=1 --branch v1.0.2 --recurse-submodules https://github.com/LunarG/gfxreconstruct.git

cd gfxreconstruct

git submodule update --init

mkdir Build
mkdir Build_x86

# Build 32-bit first then 64-bit
# This way resulting 64-bit binaries overwrite the 32-bit ones
cd Build_x86

cmake \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DCMAKE_TOOLCHAIN_FILE=cmake/toolchain/linux_x86_32.cmake \
	-DCMAKE_BUILD_TYPE=Release -G Ninja ..
ninja

ninja install

cd ..

cd Build

cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -G Ninja ..
ninja

ninja install

cd /
rm -Rf /root/gfxreconstruct
