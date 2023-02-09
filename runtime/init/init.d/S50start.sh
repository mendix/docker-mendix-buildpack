#!/bin/sh

PASSWORD=`echo -n $M2EE_ADMIN_PASS | base64`

echo "Starting app"
while :
do
    RESPONSE=$(curl \
        -d '{"action":"start","params":{}}' \
        -H "Content-Type: application/json" \
        -H "X-M2EE-Authentication: $PASSWORD" \
        -H "Connection: close" \
        -f -s \
        http://localhost:$M2EE_ADMIN_PORT)
    CODE=$?
    if [ $CODE -ne 0 ]; then
        echo "Failed to start runtime: $RESPONSE, code $CODE"
        exit $CODE
    fi
    RUNTIME_RESULT=$(echo $RESPONSE | jq -r .result)
    if [ $RUNTIME_RESULT -eq 2 ] || [ $RUNTIME_RESULT -eq 3 ]; then
        # TODO: only run DDL on master
        echo "Upgrading database"
        RESPONSE=$(curl \
            -d '{"action":"execute_ddl_commands","params":{}}' \
            -H "Content-Type: application/json" \
            -H "X-M2EE-Authentication: $PASSWORD" \
            -H "Connection: close" \
            -f -s \
            http://localhost:$M2EE_ADMIN_PORT)
        CODE=$?
        if [ $CODE -ne 0 ]; then
            echo "Failed to upgrade database: $RESPONSE, code $CODE"
            exit $CODE
        fi
        if ! echo $RESPONSE | jq -er 'contains({"result":0})' > /dev/null; then
            echo "Unexpected response: $RESPONSE"
            exit 1
        fi
    elif [ $RUNTIME_RESULT -eq 0 ]; then
        break
    else
        RUNTIME_MESSAGE=$(echo $RESPONSE | jq -r .message)
        echo "Runtime status is: $RUNTIME_MESSAGE (code $RUNTIME_RESULT)"
        exit 1
    fi
done
