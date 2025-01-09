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
  python3-pycparser \
  libclc-dev \
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

# Remove rust, overwriting with rustup toolchain.
apt-get remove -y rustc cargo

# Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"

# Needed for rusticl
rustup target add i686-unknown-linux-gnu
cargo install bindgen-cli cbindgen

apt-get build-dep -y mesa

# Move to /root/
cd /root

export CC=clang-15
export CXX=clang++-15

# Clone meson
git clone --depth=1 --branch 1.5.1 https://github.com/mesonbuild/meson.git

# Build and install DRM
git clone --depth=1 --branch libdrm-2.4.122 https://gitlab.freedesktop.org/mesa/drm.git
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
git clone --depth=1 --branch mesa-24.3.3 https://gitlab.freedesktop.org/mesa/mesa.git
cd mesa
mkdir Build
mkdir Build_x86

# Iris, anv, and Asahi disabled because it fails to find opencl-c-base.h for some reason.
export GALLIUM_DRIVERS="r300,r600,radeonsi,nouveau,virgl,svga,swrast,v3d,vc4,freedreno,etnaviv,tegra,lima,panfrost,zink,d3d12"
export VULKAN_DRIVERS="amd,broadcom,freedreno,panfrost,swrast,virtio,nouveau"

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

# Rusticl disabled because of libclang conflict.
# Same with NVK
export VULKAN_DRIVERS="amd,broadcom,freedreno,panfrost,swrast,virtio"
/root/meson/meson.py setup -Dprefix=/usr -Dlibdir=/usr/lib/i386-linux-gnu \
  -Dbuildtype=release \
  -Db_ndebug=true \
  -Dgallium-rusticl=false \
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
apt-get remove -y spirv-tools:i386 glslang-tools:i386
apt-get install -y spirv-tools glslang-tools
