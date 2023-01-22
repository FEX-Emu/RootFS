#!/bin/sh

# Move to /root/
cd /root

git clone --depth=1 https://github.com/FEX-Emu/glibc-tools.git
cd glibc-tools

mkdir Build
mkdir Build_x86

cd Build

export CC="clang"
export CXX="clang++"
export DESTDIR=$(pwd)/install/
../configure --prefix=usr/ --libdir=usr/lib/x86_64-linux-gnu/
make
make install
cp $DESTDIR/usr/lib/x86_64-linux-gnu/libSegFault.so /usr/lib/x86_64-linux-gnu/

cd ../Build_x86

export CC="clang -m32"
export CXX="clang++ -m32"
export DESTDIR=$(pwd)/install/
../configure --prefix=usr/ --libdir=usr/lib/i386-linux-gnu/
make
make install
cp $DESTDIR/usr/lib/i386-linux-gnu/libSegFault.so /usr/lib/i386-linux-gnu/
