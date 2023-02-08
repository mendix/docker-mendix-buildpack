#!/bin/sh
set -e

PASSWORD=`echo -n $M2EE_ADMIN_PASS | base64`

# TODO: set log levels

echo "Configuring logger"
RESPONSE=$(curl \
    -d '{"action":"create_log_subscriber","params":{"name":"ConsoleSubscriber","type":"console","autosubscribe":"INFO"}}' \
    -H "Content-Type: application/json" \
    -H "X-M2EE-Authentication: $PASSWORD" \
    -H "Connection: close" \
    -f -s \
    http://localhost:$M2EE_ADMIN_PORT)
CODE=$?
if [ $CODE -ne 0 ]; then
    echo "Failed to create log subscriber: $RESPONSE, code $CODE"
    exit $CODE
fi
if ! echo $RESPONSE | jq -er 'contains({"result":0})' > /dev/null; then
    echo "Unexpected response: $RESPONSE"
    exit 1
fi

echo "Starting logging"
RESPONSE=$(curl \
    -d '{"action":"start_logging"}' \
    -H "Content-Type: application/json" \
    -H "X-M2EE-Authentication: $PASSWORD" \
    -H "Connection: close" \
    -f -s \
    http://localhost:$M2EE_ADMIN_PORT)
CODE=$?
if [ $CODE -ne 0 ]; then
    echo "Failed to start logging: $RESPONSE, code $CODE"
    exit $CODE
fi
if ! echo $RESPONSE | jq -er 'contains({"result":0})' > /dev/null; then
    echo "Unexpected response: $RESPONSE"
    exit 1
fi
