#!/bin/sh
set -e

BUILDER_IMAGES_REPOSITORY=mendix/nextgen-buildpack
IMAGE_VERSIONDETECT=${BUILDER_IMAGES_REPOSITORY}/mx-version-detector
IMAGE_MXBUILD=${BUILDER_IMAGES_REPOSITORY}/mxbuild
PROJECTSOURCE=${PROJECTSOURCE:-project}
PROJECT_TAG=${PROJECT_TAG:-unknown}
TARGETIMAGE=${TARGETIMAGE:-mendixapp}
DOCKERFILE=${DOCKERFILE:-app.dockerfile}

LABELS="buildpack=mendix"

echo "Building Mendix version detector image"
docker build -f build/mxversion.dockerfile -t $IMAGE_VERSIONDETECT build

echo "Creating work volume"
WORK_VOLUME=$(docker volume create --label $LABELS)

echo "Copying files to work volume"
TRANSFER_CONTAINER=$(docker container create \
    -v $WORK_VOLUME:/workdir --label $LABELS \
    $IMAGE_VERSIONDETECT)
docker cp $PROJECTSOURCE $TRANSFER_CONTAINER:/workdir/project
docker cp init $TRANSFER_CONTAINER:/workdir/init
docker cp build $TRANSFER_CONTAINER:/workdir/build

echo "Updating permissions in work volume"
docker run -u 0:0 --rm \
    -v $WORK_VOLUME:/workdir --label $LABELS \
    $IMAGE_VERSIONDETECT \
    sh -c 'chown -R 1001:0 /workdir'

echo "Getting Mendix version"
MX_VERSION=$(docker run --rm \
    -v $WORK_VOLUME:/workdir --label $LABELS \
    $IMAGE_VERSIONDETECT \
    mx-version-detector.sh)
echo "Project is based on Mendix $MX_VERSION"

echo "Getting JVM version"
MX_MAJOR_VERSION=$(echo $MX_VERSION | head -n 1 | cut -d . -f 1)
MX_MINOR_VERSION=$(echo $MX_VERSION | head -n 1 | cut -d . -f 2)
if [ $MX_MAJOR_VERSION -le 7 ] || [ $MX_MAJOR_VERSION -eq 8 ]; then
    JAVA_VERSION=1.8.0
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

echo "Building the project MDA"
docker run --rm \
    -v $WORK_VOLUME:/workdir --label $LABELS \
    ${IMAGE_MXBUILD}:${MX_VERSION}

echo "Extracting project artifacts"
docker cp "$TRANSFER_CONTAINER:/workdir/mendix" - > app.tar

echo "Building project image"
docker build \
  --build-arg MX_VERSION=${MX_VERSION} \
  --build-arg JAVA_VERSION=${JAVA_VERSION} \
  -f ${DOCKERFILE} -t ${TARGETIMAGE} .

echo "Cleaning up"
docker rm $TRANSFER_CONTAINER
docker volume rm $WORK_VOLUME
rm app.tar
