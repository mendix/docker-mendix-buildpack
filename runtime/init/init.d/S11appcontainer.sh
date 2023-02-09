#!/bin/sh
set -e

PASSWORD=`echo -n $M2EE_ADMIN_PASS | base64`

echo "Configuring app container"
RESPONSE=$(curl \
    -d '{"action":"update_appcontainer_configuration","params":{"runtime_port":"8080","runtime_listen_addresses":"0.0.0.0","runtime_jetty_options":{}}}' \
    -H "Content-Type: application/json" \
    -H "X-M2EE-Authentication: $PASSWORD" \
    -H "Connection: close" \
    -f -s \
    http://localhost:$M2EE_ADMIN_PORT)
CODE=$?
if [ $CODE -ne 0 ]; then
    echo "Failed to configure app container: $RESPONSE, code $CODE"
    exit $CODE
fi
if ! echo $RESPONSE | jq -er 'contains({"result":0})' > /dev/null; then
    echo "Unexpected response: $RESPONSE"
    exit 1
fi
