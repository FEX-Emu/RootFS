#!/bin/sh

# Add source packages
sed -i -e "s/^# deb/deb/g" /etc/apt/sources.list
apt-get update

cd /root
export DEBIAN_FRONTEND=noninteractive
dpkg --add-architecture i386
apt-get update
apt-get upgrade -y
apt-get install -y git ninja-build clang gcc-i686-linux-gnu g++-i686-linux-gnu \
  libvulkan-dev libpciaccess-dev libglvnd-dev cargo libclang-dev \
  llvm-15 \
  llvm-15-dev \
  llvm-15-runtime \
  clang-15 \
  clang++-15 \
  spirv-tools \
  cargo \
  python3-pycparser \
  pkgconf

apt-get install -y libvulkan-dev:i386 libelf-dev:i386 libwayland-dev:i386 libwayland-egl-backend-dev:i386 \
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

# llvm-14 causes bindgen to break
apt-get remove -y llvm-14 llvm-14-runtime llvm-runtime clang-14

apt-get build-dep -y mesa

# Move to /root/
cd /root

export CC=clang-15
export CXX=clang++-15

# Clone meson
git clone --depth=1 --branch 1.3.1 https://github.com/mesonbuild/meson.git

# Build and install DRM
git clone --depth=1 --branch libdrm-2.4.119 https://gitlab.freedesktop.org/mesa/drm.git
cd drm

mkdir Build
mkdir Build_x86

cd Build
/root/meson/meson.py setup -Dprefix=/usr  -Dlibdir=/usr/lib/x86_64-linux-gnu \
  -Dbuildtype=release \
  -Db_ndebug=true \
  -Dvc4=enabled -Dtegra=enabled -Dfreedreno=enabled -Dexynos=enabled -Detnaviv=enabled \
  -Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  -Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  ..

ninja
ninja install

cd ../
cd Build_x86

/root/meson/meson.py setup -Dprefix=/usr -Dlibdir=/usr/lib/i386-linux-gnu \
  -Dbuildtype=release \
  -Db_ndebug=true \
  -Dvc4=enabled -Dtegra=enabled -Dfreedreno=enabled -Dexynos=enabled -Detnaviv=enabled \
  -Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  -Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  --cross-file /root/cross_x86 \
  ..

ninja
ninja install

# Move to /root/
cd /root

# Build and install mesa
git clone --depth=1 --branch mesa-24.1.0 https://gitlab.freedesktop.org/mesa/mesa.git
cd mesa
mkdir Build
mkdir Build_x86

export GALLIUM_DRIVERS="r300,r600,radeonsi,nouveau,virgl,svga,swrast,iris,kmsro,v3d,vc4,freedreno,etnaviv,tegra,lima,panfrost,zink,asahi,d3d12"
export VULKAN_DRIVERS="amd,broadcom,freedreno,panfrost,swrast,virtio,nouveau"

# Needed for rusticl
cargo install bindgen-cli cbindgen rustfmt
export PATH=/root/.cargo/bin:$PATH

cd Build
/root/meson/meson.py setup -Dprefix=/usr  -Dlibdir=/usr/lib/x86_64-linux-gnu \
  -Dbuildtype=release \
  -Db_ndebug=true \
  -Dgallium-rusticl=true \
  -Dgallium-drivers=$GALLIUM_DRIVERS \
  -Dvulkan-drivers=$VULKAN_DRIVERS \
  -Dplatforms=x11,wayland \
  -Dfreedreno-kmds=msm,virtio \
  -Dglvnd=enabled \
  -Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  -Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  ..

ninja
ninja install

cd ../
cd Build_x86

apt-get install -y spirv-tools:i386 glslang-tools:i386

# No rusticl for 32-bit
# No asahi for 32-bit since asahi_clc can't cross-compile
export GALLIUM_DRIVERS="r300,r600,radeonsi,nouveau,virgl,svga,swrast,iris,kmsro,v3d,vc4,freedreno,etnaviv,tegra,lima,panfrost,zink,d3d12"
/root/meson/meson.py setup -Dprefix=/usr -Dlibdir=/usr/lib/i386-linux-gnu \
  -Dbuildtype=release \
  -Db_ndebug=true \
  -Dgallium-drivers=$GALLIUM_DRIVERS \
  -Dvulkan-drivers=$VULKAN_DRIVERS \
  -Dplatforms=x11,wayland \
  -Dfreedreno-kmds=msm,virtio \
  -Dglvnd=enabled \
  -Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  -Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  --cross-file /root/cross_x86 \
  ..

ninja
ninja install

cd /

cargo uninstall bindgen-cli cbindgen rustfmt
apt-get remove -y cargo
apt-get remove -y spirv-tools:i386 glslang-tools:i386
apt-get install -y spirv-tools glslang-tools
