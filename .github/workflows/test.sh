#!/bin/bash
set -uex

docker version
docker-compose version

TEST_MDA=$1
echo "Downloading test MDA"

curl -sL -o app.mda https://s3-eu-west-1.amazonaws.com/mx-buildpack-ci/${TEST_MDA}
unzip app.mda -d project/

echo "Building test app"

export PROJECTSOURCE=project
export TARGETIMAGE=testapp

./build.sh

rm -rf app.mda project

COMPOSEFILE=docker-compose/docker-compose.yml
TIMEOUT=180s

echo "test.sh [TEST STARTED] starting docker-compose $COMPOSEFILE"
TARGETIMAGE=$TARGETIMAGE docker-compose -f $COMPOSEFILE up &

timeout $TIMEOUT bash -c 'until curl -s http://localhost:8080 | grep "<title>Mendix</title>"; do sleep 5; done'

curl -s http://localhost:8080 | grep "<title>Mendix</title>"
RETURN_CODE=$?
if [ $RETURN_CODE -eq "0" ]; then
  echo "test.sh [TEST SUCCESS] App is reachable for $COMPOSEFILE"
else
  echo "test.sh [TEST FAILED] App is not reachable in timeout delay $TIMEOUT for $COMPOSEFILE"
fi
docker-compose -f $COMPOSEFILE kill
exit $RETURN_CODE
