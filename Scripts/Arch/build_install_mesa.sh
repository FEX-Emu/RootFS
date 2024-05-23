#!/bin/sh

cd /root
pacman --noconfirm -S \
  git \
  ninja \
  clang \
  llvm lib32-llvm \
  llvm-libs lib32-llvm-libs \
  libpciaccess lib32-libpciaccess \
  glslang \
  python-mako \
  libglvnd lib32-libglvnd \
  byacc flex bison \
  wayland-protocols \
  libxrandr lib32-libxrandr \
  rust rust-bindgen \
  spirv-llvm-translator libclc spirv-tools \
  pkgconf \
  python-pycparser \
  cbindgen

# Move to /root/
cd /root

# Clone meson
git clone --depth=1 --branch 1.3.1 https://github.com/mesonbuild/meson.git

# Build and install DRM
git clone --depth=1 --branch libdrm-2.4.119 https://gitlab.freedesktop.org/mesa/drm.git
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
  -Dc_args="-m32 -mfpmath=sse -msse -msse2 -mstackrealign" \
  -Dcpp_args="-m32 -mfpmath=sse -msse -msse2 -mstackrealign" \
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
# Intel removed because it had compile errors and kernel driver doesn't work on AArch64 anyway.
export VULKAN_DRIVERS="amd,broadcom,freedreno,panfrost,swrast,virtio,nouveau"

# Needed for rusticl
cargo install bindgen-cli cbindgen rustfmt
export PATH=/root/.cargo/bin:$PATH

cd Build
/root/meson/meson.py setup -Dprefix=/usr  -Dlibdir=/usr/lib \
  -Dbuildtype=release \
  -Db_ndebug=true \
  -Dgallium-rusticl=true -Dopencl-spirv=true -Dshader-cache=enabled -Dllvm=enabled \
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

# No rusticl for 32-bit
# No asahi for 32-bit since asahi_clc can't cross-compile
export GALLIUM_DRIVERS="r300,r600,radeonsi,nouveau,virgl,svga,swrast,iris,kmsro,v3d,vc4,freedreno,etnaviv,tegra,lima,panfrost,zink,d3d12"
/root/meson/meson.py setup -Dprefix=/usr -Dlibdir=/usr/lib32 \
  -Dbuildtype=release \
  -Db_ndebug=true \
  -Dgallium-rusticl=false -Dopencl-spirv=false -Dshader-cache=enabled -Dllvm=enabled \
  -Dgallium-drivers=$GALLIUM_DRIVERS \
  -Dvulkan-drivers=$VULKAN_DRIVERS \
  -Dplatforms=x11,wayland \
  -Dfreedreno-kmds=msm,virtio \
  -Dglvnd=enabled \
  -Dc_args="-m32 -mfpmath=sse -msse -msse2 -mstackrealign" \
  -Dcpp_args="-m32 -mfpmath=sse -msse -msse2 -mstackrealign" \
  --cross-file /root/cross_x86 \
  ..

ninja
ninja install

cd /

cargo uninstall bindgen-cli cbindgen rustfmt
