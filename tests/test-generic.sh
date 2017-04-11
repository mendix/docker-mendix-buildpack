#!/bin/bash
set -u

COMPOSEFILE=$1

docker-compose -f $COMPOSEFILE up &
TIMEOUT=180
sleep $TIMEOUT
curl http://localhost:8080 | grep "<title>Mendix</title>"
RETURN_CODE=$?
if [ $RETURN_CODE -eq "0" ]; then
  echo "test.sh [SUCCES] App is reachable"
  docker-compose -f $COMPOSEFILE down
else
  echo "test.sh [FAILED] App is not reachable in timeout delay $TIMEOUT"
  docker-compose -f $COMPOSEFILE down
fi
exit $RETURN_CODE
