#!/bin/bash
set -u

make get-sample
make build-image
make run-container &
TIMEOUT=180
sleep $TIMEOUT
curl http://localhost:8080 | grep "<title>Mendix</title>"
RETURN_CODE=$?
if [ $RETURN_CODE -eq "0" ]; then
  echo "test.sh [SUCCES] App is reachable"
  # docker-compose down
  exit 0
else
  echo "test.sh [FAILED] App is not reachable in timeout delay $TIMEOUT"
  # docker-compose down
  exit $RETURN_CODE
fi
