#!/usr/bin/env bash
#
# Cross compile the Raspberry Pi distro of RTIMULib.  For further background, see
# https://github.com/RPi-Distro/RTIMULib
#
# This script draws heavily on the conventions of the Embedded Rust cross-compilation
# tools - see for example scripts such as:
#
#     https://github.com/rust-embedded/cross/blob/master/docker/musl.sh

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
    # Version of RTIMULib to build.
    local version=7.2.1

    # Ensure that we satisfy any package dependencies we need in order to build.
    local dependencies=(
        ca-certificates
        curl
        build-essential
    )

    apt-get update
    local purge_list=()
    for dep in "${dependencies[@]}"; do
        if ! dpkg -L "${dep}"; then
            apt-get install --assume-yes --no-install-recommends "${dep}"
            purge_list+=( "${dep}" )
        fi
    done

    # Create a temp directory for the build.
    local td
    td="$(mktemp -d)"
    echo "Building in ${td}"

    # Fetch the source tarball.
    pushd "${td}"
    curl --retry 3 -sSfL "https://github.com/RPi-Distro/RTIMULib/archive/V${version}.tar.gz" -O
    tar --strip-components=1 -xzf "V${version}.tar.gz"

    # Create a cross compilation build environment.
    toolchain=${1}
    echo "Cross compiling using ${toolchain} toolchain."
    mkdir -p Linux/build 
    cd Linux/build
    hide_output cmake -DCMAKE_TOOLCHAIN_FILE=/${toolchain} \
          -DBUILD_GL=OFF \
          -DBUILD_DEMOGL=OFF .. 

    # Build & install the library.
    hide_output cmake --build . 
    hide_output cmake --install .
    
    # Remove any build packages we needed.
    if (( ${#purge_list[@]} )); then
      apt-get purge --assume-yes --auto-remove "${purge_list[@]}"
    fi

    # Cleanup all the files we used.
    popd
    rm -rf "${td}"
    rm "${0}"
    rm "${toolchain}"
}

main "${@}"
