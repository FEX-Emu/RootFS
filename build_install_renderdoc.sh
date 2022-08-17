#!/bin/sh

# Move to /root/
cd /root

export DEBIAN_FRONTEND=noninteractive
apt-get install -y \
	python3-dev \
	libxcb-keysyms1-dev \
	libx11-xcb-dev \
	libx11-dev \
	libxcb-keysyms1-dev:i386 \
	libx11-xcb-dev:i386 \
	libx11-dev:i386 \
	bison \
	autoconf \
	automake \
	libpcre3-dev \
	qt5-qmake \
	libqt5svg5-dev \
	libqt5x11extras5-dev \
	cmake

# Just in case we missed some
apt-get build-dep -y renderdoc

git clone --depth=1 --branch v1.21 https://github.com/baldurk/renderdoc.git
cd renderdoc

mkdir Build
mkdir Build_x86

cd Build
cmake -DLIB_SUFFIX=/x86_64-linux-gnu \
	-DVULKAN_JSON_SUFFIX=.x86_64 \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DVULKAN_LAYER_FOLDER=/usr/share/vulkan/implicit_layer.d/ \
	..

make -j65
make install

cd ../
cd Build_x86
cmake -DLIB_SUFFIX=/i386-linux-gnu \
	-DVULKAN_JSON_SUFFIX=.i686 \
	-DENABLE_RENDERDOCCMD=False \
	-DENABLE_QRENDERDOC=False \
	-DENABLE_PYRENDERDOC=False \
	-DCMAKE_INSTALL_PREFIX=/usr \
	-DCMAKE_C_COMPILER=i686-linux-gnu-gcc \
	-DCMAKE_CXX_COMPILER=i686-linux-gnu-g++ \
	-DVULKAN_LAYER_FOLDER=/usr/share/vulkan/implicit_layer.d/ \
	..

make -j65
make install

cd /
rm -Rf /root/renderdoc
