#!/bin/bash
set -u

BASEDIR=$(dirname "$0")
COMPOSEFILE=$1

export BUILDPACK_VERSION="${BUILDPACK_VERSION:-$(cat $BASEDIR/../docker-buildpack.version)}"

echo "Testing buildpack version ${BUILDPACK_VERSION}"
echo "test.sh [TEST STARTED] starting docker-compose $COMPOSEFILE"
docker-compose -f $COMPOSEFILE up &
TIMEOUT=180
sleep $TIMEOUT
curl http://localhost:8080 | grep "<title>Mendix</title>"
RETURN_CODE=$?
if [ $RETURN_CODE -eq "0" ]; then
  echo "test.sh [TEST SUCCESS] App is reachable for $COMPOSEFILE"
  docker-compose -f $COMPOSEFILE kill
else
  echo "test.sh [TEST FAILED] App is not reachable in timeout delay $TIMEOUT for $COMPOSEFILE"
  docker-compose -f $COMPOSEFILE kill
fi
exit $RETURN_CODE
