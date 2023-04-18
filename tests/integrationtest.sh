#!/bin/sh
set -eux
docker version
docker-compose version

echo "Downwloading test project"
mkdir -p downloads build
wget https://s3-eu-west-1.amazonaws.com/mx-buildpack-ci/BuildpackTestApp-mx-7-16.mda -O downloads/application.mpk
unzip downloads/application.mpk -d build/

echo "Building app rootfs"
docker build -t mendix-rootfs:app -f rootfs-app.dockerfile .

echo "Building builder rootfs"
docker build -t mendix-rootfs:builder -f rootfs-builder.dockerfile .

echo "Building test app"
export BUILDPACK_VERSION=`git rev-parse HEAD`
docker build \
	--build-arg BUILD_PATH=build \
	--build-arg BUILDER_ROOTFS_IMAGE=mendix-rootfs:builder \
	--build-arg ROOTFS_IMAGE=mendix-rootfs:app \
	-t mendix-testapp:$BUILDPACK_VERSION .


tests/test-generic.sh tests/docker-compose-postgres.yml
#tests/test-generic.sh tests/docker-compose-sqlserver.yml
#tests/test-generic.sh tests/docker-compose-azuresql.yml
