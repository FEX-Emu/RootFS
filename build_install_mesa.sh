
# Add source packages
sed -i -e "s/^# deb/deb/g" /etc/apt/sources.list
apt-get update

cd /root
export DEBIAN_FRONTEND=noninteractive
apt-get install -y git ninja-build clang gcc-i686-linux-gnu g++-i686-linux-gnu llvm-dev libvulkan-dev
apt-get install -y libvulkan-dev:i386 libdrm-dev:i386 libelf-dev:i386 libwayland-dev:i386 libwayland-egl-backend-dev:i386 \
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
	libxxf86vm-dev:i386

apt-get build-dep -y mesa

git clone --branch mesa-21.3.0-fex-rc2 --depth=1 https://gitlab.freedesktop.org/sonicadvance1/mesa.git

cd mesa
mkdir Build
mkdir Build_x86

export DRI_DRIVERS="i915,i965,r100,r200,nouveau"
export GALLIUM_DRIVERS="r300,r600,radeonsi,nouveau,virgl,svga,swrast,iris,kmsro,v3d,vc4,freedreno,etnaviv,tegra,lima,panfrost,zink,asahi"
export VULKAN_DRIVERS="amd,intel,freedreno,swrast,broadcom"

cd Build
meson -Dprefix=/usr  -Dlibdir=/usr/lib/x86_64-linux-gnu \
	-Dbuildtype=release \
	-Db_ndebug=true \
	-Ddri-drivers=$DRI_DRIVERS \
	-Dgallium-drivers=$GALLIUM_DRIVERS \
	-Dvulkan-drivers=$VULKAN_DRIVERS \
	-Dplatforms=x11,wayland \
	-Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
	-Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
	..

ninja
ninja install

cd ../
cd Build_x86

meson -Dprefix=/usr -Dlibdir=/usr/lib/i386-linux-gnu \
	-Dbuildtype=release \
	-Db_ndebug=true \
	-Ddri-drivers=$DRI_DRIVERS \
	-Dgallium-drivers=$GALLIUM_DRIVERS \
	-Dvulkan-drivers=$VULKAN_DRIVERS \
	-Dplatforms=x11,wayland \
	-Dc_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
	-Dcpp_args="-mfpmath=sse -msse -msse2 -mstackrealign" \
	--cross-file /root/cross_x86 \
	..

ninja
ninja install

cd /
