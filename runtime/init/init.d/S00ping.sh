#!/bin/sh

PASSWORD=`echo -n $M2EE_ADMIN_PASS | base64`

echo "Waiting for runtime to become ready"
while :
do
    RESPONSE=$(curl \
        -d '{"action":"echo","params":{"echo": "ping"}}' \
        -H "Content-Type: application/json" \
        -H "X-M2EE-Authentication: $PASSWORD" \
        -H "Connection: close" \
        -f -s \
        http://localhost:$M2EE_ADMIN_PORT)
    CODE=$?
    if [ $CODE -eq 0 ]; then
        break
    else
        sleep 1
    fi
done

set -e

if ! echo $RESPONSE | jq -er 'contains({"feedback":{"echo":"pong"},"result":0})' > /dev/null; then
    echo "Unexpected response: $RESPONSE"
    exit 1
fi
