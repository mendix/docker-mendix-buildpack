#!/bin/sh
set -e

BUILDER_IMAGES_REPOSITORY=mendix/nextgen-buildpack
IMAGE_VERSIONDETECT=${BUILDER_IMAGES_REPOSITORY}/mx-version-detector
IMAGE_MXBUILD=${BUILDER_IMAGES_REPOSITORY}/mxbuild
IMAGE_RUNTIME=${BUILDER_IMAGES_REPOSITORY}/runtime-base
PROJECTSOURCE=${PROJECTSOURCE:-project}
PROJECT_TAG=${PROJECT_TAG:-unknown}
TARGETIMAGE=${TARGETIMAGE:-mendixapp}
DOCKERFILE=${DOCKERFILE:-app.dockerfile}

LABELS="buildpack=mendix"

echo "Building Mendix version detector image"
docker build --force-rm \
    -f build/mxversion.dockerfile -t $IMAGE_VERSIONDETECT build

echo "Getting Mendix version"
DETECT_VERSION_CONTAINER=$(docker container create \
    --label $LABELS \
    $IMAGE_VERSIONDETECT)
docker cp $PROJECTSOURCE $DETECT_VERSION_CONTAINER:/workdir/project
MX_VERSION=$(docker start -a $DETECT_VERSION_CONTAINER)
echo "Project is based on Mendix $MX_VERSION"
docker rm $DETECT_VERSION_CONTAINER

echo "Getting JVM version"
MX_MAJOR_VERSION=$(echo $MX_VERSION | head -n 1 | cut -d . -f 1)
MX_MINOR_VERSION=$(echo $MX_VERSION | head -n 1 | cut -d . -f 2)
if [ $MX_MAJOR_VERSION -le 7 ]; then
    JAVA_VERSION=1.8.0
    DOTNET_VERSION="mono520"
elif [ $MX_MAJOR_VERSION -eq 8 ]; then
    JAVA_VERSION=11
    DOTNET_VERSION="mono520"
elif [ $MX_MAJOR_VERSION -eq 9 ] && [ $MX_MINOR_VERSION -lt 16 ]; then
    JAVA_VERSION=11
    DOTNET_VERSION="mono520"
elif [ $MX_MAJOR_VERSION -eq 9 ] && [ $MX_MINOR_VERSION -ge 16 ]; then
    JAVA_VERSION=11
    DOTNET_VERSION="dotnet6"
else
    echo "Unsupported Mendix version: ${MX_MAJOR_VERSION}.${MX_MINOR_VERSION}"
fi

echo "Using Java $JAVA_VERSION and .NET $DOTNET_VERSION"

echo "Building MxBuild $MX_VERSION image"
docker build \
  --build-arg MX_VERSION=${MX_VERSION} \
  --build-arg JAVA_VERSION=${JAVA_VERSION} \
  --build-arg DOTNET_VERSION=${DOTNET_VERSION} \
  -f build/mxbuild.dockerfile -t ${IMAGE_MXBUILD}:${MX_VERSION} build

echo "Building Mendix Runtime $MX_VERSION image"
docker build \
  --build-arg MX_VERSION=${MX_VERSION} \
  --build-arg JAVA_VERSION=${JAVA_VERSION} \
  -f runtime/runtime.dockerfile -t ${IMAGE_RUNTIME}:${MX_VERSION} runtime

echo "Building app image"
docker build --force-rm \
  --build-arg MX_VERSION=${MX_VERSION} \
  --build-arg IMAGE_MXBUILD=${IMAGE_MXBUILD} \
  --build-arg IMAGE_RUNTIME=${IMAGE_RUNTIME} \
  -f ${DOCKERFILE} -t ${TARGETIMAGE} ${PROJECTSOURCE}

echo "Cleaning up"
