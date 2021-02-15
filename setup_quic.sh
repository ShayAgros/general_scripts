#!/usr/bin/env bash

set -e

sudo pip3 install cmake

sudo yum install pkgconfig autoconf automake libtool libev-devel.x86_64 gnutls-devel.x86_64 libunwind-devel.x86_64 golang -y

git clone https://boringssl.googlesource.com/boringssl ~/boringssl
cd ~/boringssl
git checkout 78f15a6aa9f11ab7cff736f920c4858cc38264fb
mkdir build && cd build
cmake ..
make -j $(getconf _NPROCESSORS_ONLN)

git clone --depth 1 -b OpenSSL_1_1_1g-quic-draft-33 https://github.com/tatsuhiro-t/openssl
cd openssl
# For Linux
./config enable-tls1_3 --prefix=$PWD/build
make -j$(nproc)
make install_sw
cd ..
git clone https://github.com/ngtcp2/nghttp3
cd nghttp3
autoreconf -i
./configure --prefix=$PWD/build --enable-lib-only
make -j$(nproc) check
make install
cd ..
git clone https://github.com/ngtcp2/ngtcp2
cd ngtcp2
autoreconf -i
# For Mac users who have installed libev with MacPorts, append
# ',-L/opt/local/lib' to LDFLAGS, and also pass
# CPPFLAGS="-I/opt/local/include" to ./configure.
./configure PKG_CONFIG_PATH=$PWD/../openssl/build/lib/pkgconfig:$PWD/../nghttp3/build/lib/pkgconfig LDFLAGS="-Wl,-rpath,$PWD/../openssl/build/lib"
make -j$(nproc) check
