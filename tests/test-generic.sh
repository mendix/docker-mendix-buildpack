#!/bin/bash
set -u

COMPOSEFILE=$1

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
