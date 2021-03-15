#!/bin/bash
#
# Push the Docker image to Docker Hub.

set -e 

VERSION=$(cat VERSION)

CONTAINER="solimike/raspberry_cross"

echo "Upload ${CONTAINER} build container at version: ${VERSION}"

docker login -u solimike
docker push ${CONTAINER}:armv7-unknown-linux-gnueabihf-${VERSION} 
