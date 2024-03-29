#!/usr/bin/env bash
#
# Cross compile the Raspberry Pi distro of Python.  
#
# This script draws heavily on the conventions of the Embedded Rust cross-compilation
# tools - see for example scripts such as:
#
#     https://github.com/rust-embedded/cross/blob/master/docker/musl.sh
#
# Sources of info:
#
#   1)  https://gitlab.com/Spindel/rust-python-cross-example
#   2)  https://raspberrypi.stackexchange.com/questions/66528/how-to-cross-compile-python-3-6-for-the-raspberry-pi
#   3)  https://github.com/rust-embedded/cross/issues/556

set -x
set -euo pipefail

hide_output() {
    set +x
    trap "
      echo 'ERROR: An error was encountered with the build.'
      cat /tmp/build.log
      exit 1
    " ERR
    bash -c 'while true; do sleep 30; echo $(date) - building ...; done' &
    PING_LOOP_PID=$!
    "${@}" &> /tmp/build.log
    trap - ERR
    kill "${PING_LOOP_PID}"
    set -x
}

main() {
    # Version of Python to build.
    local version=${1}
    echo "Building cross compiled Python V${version}"

    # Create a temp directory for the build.
    local td
    td="$(mktemp -d)"
    pushd "${td}"
    echo "Building in ${td}"

    # Fetch ARM architecture dependencies: tell APT where to find the resources and
    # add the architecture first. The addition of armhf to the sources list is a bit
    # crude so triggers some "not found" errors in the update which we have to ignore.
    sed -i "s/i386]/i386,armhf]/" /etc/apt/sources.list
    dpkg --add-architecture armhf
    apt-get update || true
    apt-get install --assume-yes libssl-dev:armhf \
                                 libffi-dev:armhf \
                                 zlib1g-dev:armhf \
                                 libjpeg-dev:armhf

    # Fetch the source tarball.
    curl --retry 3 -sSfL "https://www.python.org/ftp/python/${version}/Python-${version}.tgz" -O
    tar --strip-components=1 -xzf "Python-${version}.tgz"

    # Configure the toolchain and then cross-compile into the alternate location.
    export CC=arm-linux-gnueabihf-gcc
    export LD=arm-linux-gnueabihf-ld
    export CXX=arm-linux-gnueabihf-g++
    export CPP=arm-linux-gnueabihf-cpp
    export READELF=arm-linux-gnueabihf-readelf
    export RANLIB=arm-linux-gnueabihf-ranlib
    export AR=arm-linux-gnueabihf-ar

    echo ac_cv_file__dev_ptmx=no > ./config.site
    echo ac_cv_file__dev_ptc=no >> ./config.site

    CONFIG_SITE=config.site ./configure --prefix=/usr/arm-linux-gnueabihf \
                                        --build=x86_64-pc-linux-gnu \
                                        --host=arm-unknown-linux-gnueabihf \
                                        --disable-ipv6 \
                                        --enable-shared
    make install

    # Cleanup all the files we used.
    popd
    rm -rf "${td}"
    rm "${0}"
}

main "${@}"
