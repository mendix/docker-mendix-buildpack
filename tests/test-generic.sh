#!/bin/bash
set -u

docker-compose -f docker-compose-mysql.yml up &
TIMEOUT=180
sleep $TIMEOUT
curl http://localhost:8080 | grep "<title>Mendix</title>"
RETURN_CODE=$?
if [ $RETURN_CODE -eq "0" ]; then
  echo "test.sh [SUCCES] App is reachable"
  docker-compose -f docker-compose-mysql.yml down
  exit 0
else
  echo "test.sh [FAILED] App is not reachable in timeout delay $TIMEOUT"
  docker-compose -f docker-compose-mysql.yml down
  exit $RETURN_CODE
fi
