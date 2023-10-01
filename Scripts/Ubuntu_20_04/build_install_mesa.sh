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

export DEBIAN_FRONTEND=noninteractive
apt-get install -y git ninja-build clang gcc-i686-linux-gnu g++-i686-linux-gnu \
  llvm-15-dev libvulkan-dev libpciaccess-dev libglvnd-dev

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

# Move to /root/
cd /root

# Build and install mesa
git clone --depth=1 --branch mesa-23.2.1 https://gitlab.freedesktop.org/mesa/mesa.git

cd mesa
mkdir Build
mkdir Build_x86

export GALLIUM_DRIVERS="r300,r600,radeonsi,nouveau,virgl,svga,swrast,iris,kmsro,v3d,vc4,freedreno,etnaviv,tegra,lima,panfrost,zink,asahi,d3d12"
export VULKAN_DRIVERS="amd,intel,freedreno,swrast,broadcom,panfrost,virtio"

# llvmspirvlib-dev is llvm-13 while llvm-14 is used in Ubuntu 22.04. Two version need to match. Can't use rusticl because of this.
cd Build
/root/meson/meson.py -Dprefix=/usr  -Dlibdir=/usr/lib/x86_64-linux-gnu \
  -Dbuildtype=release \
  -Db_ndebug=true \
  -Dgallium-drivers=$GALLIUM_DRIVERS \
  -Dvulkan-drivers=$VULKAN_DRIVERS \
  -Dplatforms=x11 \
  -Dglvnd=true \
  -Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  -Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  ..

# Comment while waiting
ninja
ninja install

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


dpkg --configure -a
apt-get remove -y llvm
apt-get remove -y llvm-15-tools llvm
apt-get install -y python3-pip
pip3 install mako
apt-get install -y llvm-15-dev:i386 llvm-15-tools:i386 python3:i386
pip3 install mako

update-alternatives --install /usr/bin/llvm-config llvm-config-15 /usr/bin/llvm-config-15 10

cd /root/drm/
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

cd /root/mesa/
cd Build_x86

# llvmspirvlib-dev:i386 doesn't exist so rusticl can't be used on 32-bit
/root/meson/meson.py -Dprefix=/usr -Dlibdir=/usr/lib/i386-linux-gnu \
  -Dbuildtype=release \
  -Db_ndebug=true \
  -Dgallium-drivers=$GALLIUM_DRIVERS \
  -Dvulkan-drivers=$VULKAN_DRIVERS \
  -Dplatforms=x11 \
  -Dglvnd=true \
  -Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  -Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
  --cross-file /root/cross_x86 \
  ..

ninja
ninja install

cd /

apt-get install -y xserver-xorg llvm-15 ibus python3   apport aptdaemon gdm3 gnome-control-center gnome-online-accounts gnome-shell ibus language-selector-common language-selector-gnome libclang-cpp15 libsmbclient llvm-10-dev llvm-10-tools llvm-12-dev llvm-12-tools llvm-15 llvm-15-linker-tools llvm-15-runtime networkd-dispatcher python3 python3-apport python3-apt python3-aptdaemon python3-aptdaemon.gtk3widgets python3-cairo python3-cffi-backend python3-cryptography python3-cups python3-cupshelpers python3-dbus python3-dev python3-gi python3-ibus-1.0 python3-keyring python3-launchpadlib python3-lazr.restfulclient python3-ldb python3-macaroonbakery python3-mako python3-markupsafe python3-minimal python3-nacl python3-oauthlib python3-protobuf python3-pymacaroons python3-secretstorage python3-simplejson python3-software-properties python3-systemd python3-talloc python3-yaml python3.8 python3.8-dev python3.8-minimal samba-libs software-properties-common system-config-printer system-config-printer-common system-config-printer-udev ubuntu-session unattended-upgrades xserver-xorg
