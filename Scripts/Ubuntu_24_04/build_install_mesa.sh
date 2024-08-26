#!/bin/sh

# Add source packages
sed -i -e "s/^Types: deb/Types: deb deb-src/g" /etc/apt/sources.list.d/ubuntu.sources
apt-get update

cd /root
export DEBIAN_FRONTEND=noninteractive
dpkg --add-architecture i386
apt-get update
apt-get upgrade -y
apt-get install -y git ninja-build clang gcc-i686-linux-gnu g++-i686-linux-gnu \
  llvm-dev libvulkan-dev libpciaccess-dev libglvnd-dev cargo libclang-dev \
  libclang-common-18-dev \
  spirv-tools \
  libclc-18-dev \
  python3-pycparser \
  curl \
  wget \
  lsb-release \
  python3-packaging \
  python3-mako \
  python3-ply \
  software-properties-common \
  glslang-tools \
  libelf-dev \
  bison \
  byacc \
  flex \
  libexpat1-dev \
  libglvnd-core-dev \
  libsensors-dev \
  libwayland-dev \
  libwayland-egl-backend-dev \
  libx11-dev \
  libx11-xcb-dev \
  libzstd-dev \
  libvulkan-dev \
  libelf-dev \
  libwayland-dev \
  libwayland-egl-backend-dev \
  libpciaccess-dev \
  libx11-dev \
  libx11-xcb-dev \
  libxcb-dri3-dev \
  libxcb-dri2-0-dev \
  libxcb-glx0-dev \
  libxcb-present-dev \
  libxcb-randr0-dev \
  libxcb-shm0-dev \
  libxcb-sync-dev \
  libxcb-xfixes0-dev \
  libxdamage-dev \
  libxext-dev \
  libxfixes-dev \
  libxrandr-dev \
  libxshmfence-dev \
  libxxf86vm-dev \
  libglvnd-dev \
  libelf-dev \
  cbindgen

apt-get install -y \
  libvulkan-dev:i386 \
  libelf-dev:i386 \
  libwayland-dev:i386 \
  libwayland-egl-backend-dev:i386 \
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
  libglvnd-dev:i386 \
  libelf-dev:i386 \
  pkgconf:i386

# Remove rust, overwriting with rustup toolchain.
apt-get remove -y rustc cargo

# Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"

apt-get build-dep -y mesa

apt-get install -y libllvmspirvlib-18-dev

# Move to /root/
cd /root

export CC=clang
export CXX=clang++

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
git clone --depth=1 --branch mesa-24.2.0 https://gitlab.freedesktop.org/mesa/mesa.git
cd mesa
mkdir Build
mkdir Build_x86

# Iris, anv, and Asahi disabled because it fails to find opencl-c-base.h for some reason.
export GALLIUM_DRIVERS="r300,r600,radeonsi,nouveau,virgl,svga,swrast,v3d,vc4,freedreno,etnaviv,tegra,lima,panfrost,zink,d3d12"
export VULKAN_DRIVERS="amd,broadcom,freedreno,panfrost,swrast,virtio,nouveau"

# Needed for rusticl
rustup target add i686-unknown-linux-gnu
cargo install bindgen-cli cbindgen

# Rusticl disabled due to compile failure
cd Build
/root/meson/meson.py setup -Dprefix=/usr  -Dlibdir=/usr/lib/x86_64-linux-gnu \
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
  ..

ninja
ninja install

cd ../
cd Build_x86

# Work around a packaging bug.
rm /usr/lib/llvm-18/lib/libLLVM.so.1

apt-get install -y \
  libllvm18:i386 \
  spirv-tools:i386 \
  glslang-tools:i386 \
  libclang-common-18-dev:i386 \
  libllvmspirvlib-18-dev:i386

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

cargo uninstall bindgen-cli cbindgen
apt-get remove -y rustup
# Work around canonical failing to package libllvm18 correctly.
mkdir /root/libllvm_i386/
cp /usr/lib/llvm-18/lib/libLLVM.so.1 /root/libllvm_i386/

apt-get remove -y spirv-tools:i386 glslang-tools:i386 libllvm18:i386

# Reinstall libllvm18 once libllvm18:i386 is removed
# This fixes the deleted libLLVM.so.1 from earlier
apt-get install -y --reinstall libllvm18
apt-get install -y spirv-tools glslang-tools

# Mark libllvm18 as manual so it doesn't get autoremoved.
apt-mark manual libllvm18

# Copy back over the i386 llvm library that we saved
cp /root/libllvm_i386/libLLVM.so.1 /usr/lib/i386-linux-gnu/libLLVM-18.so.1
ln -s libLLVM-18.so.1 /usr/lib/i386-linux-gnu/libLLVM-18.so
ln -s libLLVM-18.so.1 /usr/lib/i386-linux-gnu/libLLVM.so.18.1
rm -Rf /root/libllvm_i386
