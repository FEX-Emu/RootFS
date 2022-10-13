#!/bin/sh

# Add source packages
sed -i -e "s/^# deb/deb/g" /etc/apt/sources.list
apt-get update

cd /root
export DEBIAN_FRONTEND=noninteractive
apt-get install -y git ninja-build clang gcc-i686-linux-gnu g++-i686-linux-gnu \
	llvm-dev libvulkan-dev libpciaccess-dev libglvnd-dev

apt-get install -y libvulkan-dev:i386 libdrm-dev:i386 libelf-dev:i386 libwayland-dev:i386 libwayland-egl-backend-dev:i386 \
	libpciaccess-dev:i386 \
	libx11-dev:i386 \
	libx11-xcb-dev:i386 \
	libxcb-dri3-dev:i386 \
	libxcb-dri2-0-dev:i386 \
	libxcb-glx0-dev:i386 \
	libxcb-present-dev:i386 \
	libxcb-randr0-dev:i386 \
	libxcb-shm0-dev:i386 \
	libxcb-sync-dev:i386 \
	libxcb-xfixes0-dev:i386 \
	libxdamage-dev:i386 \
	libxext-dev:i386 \
	libxfixes-dev:i386 \
	libxrandr-dev:i386 \
	libxshmfence-dev:i386 \
	libxxf86vm-dev:i386 \
	libglvnd-dev:i386

apt-get build-dep -y mesa

# Move to /root/
cd /root

# Clone meson
git clone --depth=1 --branch 0.63 https://github.com/mesonbuild/meson.git

# Build and install DRM
git clone --depth=1 --branch libdrm-2.4.110 https://gitlab.freedesktop.org/mesa/drm.git
cd drm

mkdir Build
mkdir Build_x86

cd Build
/root/meson/meson.py -Dprefix=/usr  -Dlibdir=/usr/lib/x86_64-linux-gnu \
	-Dbuildtype=release \
	-Db_ndebug=true \
	-Dvc4=true -Dtegra=true -Dfreedreno=true -Dexynos=true -Detnaviv=true \
	-Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
	-Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
	..

ninja
ninja install

cd ../
cd Build_x86

/root/meson/meson.py -Dprefix=/usr -Dlibdir=/usr/lib/i386-linux-gnu \
	-Dbuildtype=release \
	-Db_ndebug=true \
	-Dvc4=true -Dtegra=true -Dfreedreno=true -Dexynos=true -Detnaviv=true \
	-Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
	-Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
	--cross-file /root/cross_x86 \
	..

ninja
ninja install

# Move to /root/
cd /root

# Build and install mesa
git clone https://gitlab.freedesktop.org/mesa/mesa.git

cd mesa
git checkout f8f4648cac19b5d3e67596f1b8c155c61f4f1c32
mkdir Build
mkdir Build_x86

export GALLIUM_DRIVERS="r300,r600,radeonsi,nouveau,virgl,svga,swrast,iris,kmsro,v3d,vc4,freedreno,etnaviv,tegra,lima,panfrost,zink,asahi,d3d12"
export VULKAN_DRIVERS="amd,intel,freedreno,swrast,broadcom,panfrost,virtio-experimental"

# llvmspirvlib-dev is llvm-13 while llvm-14 is used in Ubuntu 22.04. Two version need to match. Can't use rusticl because of this.
cd Build
/root/meson/meson.py -Dprefix=/usr  -Dlibdir=/usr/lib/x86_64-linux-gnu \
	-Dbuildtype=release \
	-Db_ndebug=true \
	-Dgallium-drivers=$GALLIUM_DRIVERS \
	-Dvulkan-drivers=$VULKAN_DRIVERS \
	-Dplatforms=x11,wayland \
	-Dglvnd=true \
	-Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
	-Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
	..

ninja
ninja install

cd ../
cd Build_x86

# llvmspirvlib-dev:i386 doesn't exist so rusticl can't be used on 32-bit
/root/meson/meson.py -Dprefix=/usr -Dlibdir=/usr/lib/i386-linux-gnu \
	-Dbuildtype=release \
	-Db_ndebug=true \
	-Dgallium-drivers=$GALLIUM_DRIVERS \
	-Dvulkan-drivers=$VULKAN_DRIVERS \
	-Dplatforms=x11,wayland \
	-Dglvnd=true \
	-Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
	-Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
	--cross-file /root/cross_x86 \
	..

ninja
ninja install

cd /
