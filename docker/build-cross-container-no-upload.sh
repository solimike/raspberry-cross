#!/bin/bash
set -e 

VERSION=$1

CONTAINER="solimike/raspberry_cross"

echo "Create ${CONTAINER} build container"
echo "        version: ${VERSION}"
echo "  PARALLEL_MAKE: ${PARALLEL_MAKE}"
echo "${VERSION}" > ../VERSION

docker build -f Dockerfile.armv7-unknown-linux-gnueabihf.rpi \
             --build-arg PARALLEL_MAKE=-j4 \
             -t ${CONTAINER}:armv7-unknown-linux-gnueabihf-${VERSION} .
