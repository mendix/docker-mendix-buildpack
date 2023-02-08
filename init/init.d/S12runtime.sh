#!/bin/sh
set -e

PASSWORD=`echo -n $M2EE_ADMIN_PASS | base64`

echo "Processing constants"
APP_CONSTANTS=$(cat /opt/mendix/app/model/metadata.json | \
  jq -rc '.Constants | map({(.Name) : .DefaultValue}) | add')

echo "Processing environment variables"

RUNTIME_OPTIONS='{"com.mendix.core.isClusterSlave":false,"BasePath":"/opt/mendix/app","RuntimePath":"/opt/mendix/runtime"}'
for VARIABLE in $(printenv)
do
    case $VARIABLE in
    MX_*)
        # Override default constants with values from environment
        CONSTANT_NAME=$(echo -n $VARIABLE | cut -d '=' -f -1 | cut -d _ -f 2- | sed s/_/./)
        CONSTANT_VALUE=$(echo -n $VARIABLE | cut -d '=' -f 2-)
        APP_CONSTANTS=$(echo -n $APP_CONSTANTS | \
            jq -rc --arg name "$CONSTANT_NAME" --arg value "$CONSTANT_VALUE" \
            '. + { ($name): ($value) }')
        ;;
    MXRUNTIME_*)
        # Set custom runtime settings
        VALUE_NAME=$(echo -n $VARIABLE | cut -d '=' -f -1 | cut -d _ -f 2- | sed s/_/./)
        VALUE_VALUE=$(echo -n $VARIABLE | cut -d '=' -f 2-)
        RUNTIME_OPTIONS=$(echo -n $RUNTIME_OPTIONS | \
            jq -rc --arg name "$VALUE_NAME" --arg value "$VALUE_VALUE" \
            '. + { ($name): ($value) }')
        ;;
    esac
done

# TODO: set master/slave
# TODO: set DTAPMode
RUNTIME_OPTIONS=$(echo -n $RUNTIME_OPTIONS | \
    jq -rc --arg constants "$APP_CONSTANTS" \
    '. + { MicroflowConstants: ($constants) }')
    
# TODO: set scheduled events
RUNTIME_OPTIONS=$(echo -n $RUNTIME_OPTIONS | \
    jq -rc \
    '. + { ScheduledEventExecution: "ALL" }')

echo "Configuring runtime"
UPDATE_CONFIGURATION_COMMAND=$(printf '{"action":"update_configuration","params":%s}' "$RUNTIME_OPTIONS")
RESPONSE=$(curl \
    -d "$UPDATE_CONFIGURATION_COMMAND" \
    -H "Content-Type: application/json" \
    -H "X-M2EE-Authentication: $PASSWORD" \
    -H "Connection: close" \
    -f -s \
    http://localhost:$M2EE_ADMIN_PORT)
CODE=$?
if [ $CODE -ne 0 ]; then
    echo "Failed to configure runtime: $RESPONSE, code $CODE"
    exit $CODE
fi
if ! echo $RESPONSE | jq -er 'contains({"result":0})' > /dev/null; then
    echo "Unexpected response: $RESPONSE"
    exit 1
fi
