#!/bin/sh

cd /root
/root/mega_install_packages.sh \
  git \
  ninja \
  clang \
  llvm lib32-llvm \
  llvm-libs lib32-llvm-libs \
  libpciaccess lib32-libpciaccess \
  glslang \
  python-mako \
  python-yaml \
  python-ply \
  libglvnd lib32-libglvnd \
  byacc flex bison \
  wayland-protocols \
  libxrandr lib32-libxrandr \
  spirv-llvm-translator libclc spirv-tools \
  lib32-spirv-tools \
  lib32-spirv-llvm-translator \
  lib32-clang \
  pkgconf \
  python-setuptools \
  python-mako \
  python-pycparser

# Install rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
. "$HOME/.cargo/env"

# Move to /root/
cd /root

# Clone meson
git clone --depth=1 --branch 1.10.0 https://github.com/mesonbuild/meson.git

# Build and install DRM
git clone --depth=1 --branch libdrm-2.4.122 https://gitlab.freedesktop.org/mesa/drm.git
cd drm

mkdir Build
mkdir Build_x86

cd Build
/root/meson/meson.py setup -Dprefix=/usr  -Dlibdir=/usr/lib \
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

/root/meson/meson.py setup -Dprefix=/usr -Dlibdir=/usr/lib32 \
  -Dbuildtype=release \
  -Db_ndebug=true \
  -Dvc4=enabled -Dtegra=enabled -Dfreedreno=enabled -Dexynos=enabled -Detnaviv=enabled \
  --cross-file /root/cross_x86 \
  ..

ninja
ninja install

# Move to /root/
cd /root

# Build and install mesa
git clone --depth=1 --branch mesa-25.3.3 https://gitlab.freedesktop.org/mesa/mesa.git
cd mesa
mkdir Build
mkdir Build_x86

export GALLIUM_DRIVERS="asahi,d3d12,etnaviv,freedreno,iris,lima,llvmpipe,nouveau,panfrost,r300,r600,radeonsi,svga,tegra,v3d,vc4,virgl,zink"
export VULKAN_DRIVERS="amd,broadcom,freedreno,intel,panfrost,swrast,virtio,nouveau,asahi"

# Needed for rusticl
rustup target add i686-unknown-linux-gnu
cargo install bindgen-cli cbindgen

cd Build
/root/meson/meson.py setup -Dprefix=/usr  -Dlibdir=/usr/lib \
  -Dbuildtype=release \
  -Db_ndebug=true \
  -Dgallium-rusticl=true -Dshader-cache=enabled -Dllvm=enabled \
  -Dgallium-drivers=$GALLIUM_DRIVERS \
  -Dvulkan-drivers=$VULKAN_DRIVERS \
  -Dplatforms=x11,wayland \
  -Dfreedreno-kmds=msm,virtio,kgsl \
  -Dglvnd=enabled \
  -Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  -Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  ..

ninja
ninja install

cd ../
cd Build_x86

# Apparently meson doesn't know how to pass arguments to bindgen. Good job.
export BINDGEN_EXTRA_CLANG_ARGS="--target=i686-unknown-linux-gnu"

/root/meson/meson.py setup -Dprefix=/usr -Dlibdir=/usr/lib32 \
  -Dbuildtype=release \
  -Db_ndebug=true \
  -Dgallium-rusticl=true -Dshader-cache=enabled -Dllvm=enabled \
  -Dgallium-drivers=$GALLIUM_DRIVERS \
  -Dvulkan-drivers=$VULKAN_DRIVERS \
  -Dplatforms=x11,wayland \
  -Dfreedreno-kmds=msm,virtio,kgsl \
  -Dglvnd=enabled \
  --cross-file /root/cross_x86 \
  ..

ninja
ninja install

cd /

cargo uninstall bindgen-cli cbindgen
