#!/bin/sh
set -e

PASSWORD=`echo -n $M2EE_ADMIN_PASS | base64`

echo "Shutting down Mendix Runtime"
RESPONSE=$(curl \
    -d '{"action":"shutdown"}' \
    -H "Content-Type: application/json" \
    -H "X-M2EE-Authentication: $PASSWORD" \
    -H "Connection: close" \
    -f -s \
    http://127.0.0.1:$M2EE_ADMIN_PORT)
CODE=$?
if [ $CODE -ne 0 ]; then
    echo "Failed to shut down runtime: $RESPONSE, code $CODE"
    exit $CODE
fi
if ! echo $RESPONSE | jq -er 'contains({"result":0})' > /dev/null; then
    echo "Unexpected response: $RESPONSE"
    exit 1
fi
