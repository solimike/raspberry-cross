#!/usr/bin/env bash
#
# Cross compile the Raspberry Pi distro of Python.  
#
# This script draws heavily on the conventions of the Embedded Rust cross-compilation
# tools - see for example scripts such as:
#
#     https://github.com/rust-embedded/cross/blob/master/docker/musl.sh
#
# First of all we build the Python for the container itself (i.e. a native build)
# then we do a cross compilation for the target ARM architecture. This is necessary
# because the cross-complilation of Python relies on a host installation of Python and
# the Python 3.5 that is currently packaged with the Ubuntu 16.04 that is the base for 
# Rusts cross compilation tools is too old to support cross compilation of later 
# versions of Python (e.g. Python 3.7) that rely on features like f-strings.
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
    echo "Building native Python V${version}"

    # Create a temp directory for the build.
    local td
    td="$(mktemp -d)"
    echo "Building in ${td}"

    # Fetch the source tarball.
    pushd "${td}"
    curl --retry 3 -sSfL "https://www.python.org/ftp/python/${version}/Python-${version}.tgz" -O
    tar --strip-components=1 -xzf "Python-${version}.tgz"

    # Do the native build. The subsequent cross-compile needs "python" to refer
    # to the python3 executable.
    # ./configure --enable-shared
    ./configure 
    make install
    ln -s python3 /usr/local/bin/python

    # Cleanup all the files we used.
    popd
    rm -rf "${td}"
    rm "${0}"
}

main "${@}"
