#!/bin/bash
set -u

BASEDIR=$(dirname "$0")
COMPOSEFILE=$1
TIMEOUT=180s

export BUILDPACK_VERSION="${BUILDPACK_VERSION:-$(cat $BASEDIR/../docker-buildpack.version)}"

echo "Testing buildpack version ${BUILDPACK_VERSION}"
echo "test.sh [TEST STARTED] starting docker-compose $COMPOSEFILE"
docker-compose -f $COMPOSEFILE up &

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
