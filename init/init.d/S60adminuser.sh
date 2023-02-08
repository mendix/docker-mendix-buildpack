#!/bin/sh
set -e

PASSWORD=`echo -n $M2EE_ADMIN_PASS | base64`

# TODO: only create admin user on master
# TODO: allow to choose the admin password

echo "Creating admin user"
RESPONSE=$(curl \
    -d '{"action":"create_admin_user","params":{"password":"Password1!"}}' \
    -H "Content-Type: application/json" \
    -H "X-M2EE-Authentication: $PASSWORD" \
    -H "Connection: close" \
    -f -s \
    http://localhost:$M2EE_ADMIN_PORT)
CODE=$?
if [ $CODE -ne 0 ]; then
    echo "Failed to create admin user: $RESPONSE, code $CODE"
    exit $CODE
fi
if ! echo $RESPONSE | jq -er 'contains({"result":0})' > /dev/null; then
    echo "Unexpected response: $RESPONSE"
    exit 1
fi
