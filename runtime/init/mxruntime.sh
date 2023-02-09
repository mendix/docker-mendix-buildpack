#!/bin/bash
set -e

export BUILDPACK_INIT=${BUILD_PACK_INIT:-/opt/mendix/init}
export M2EE_ADMIN_PASS=$(cat /dev/random | tr -dc 'a-zA-Z0-9' | fold -w ${1:-32} | head -n 1)
export M2EE_ADMIN_LISTEN_ADDRESSES=127.0.0.1
export M2EE_ADMIN_PORT=9000

EXITCODE=0

# Intercept SIGTERM to perform a clean shutdown of the runtime
function shutdown_runtime()
{
    ${BUILDPACK_INIT}/stop.sh

    CODE=$?
    if [ $CODE -ne 0 ]; then
        echo "Failed to perform a clean shutdown (error $CODE), exiting"
        kill $MXRUNTIME_PID
        EXITCODE=1
    fi
}
trap shutdown_runtime SIGINT SIGTERM

MX_INSTALL_PATH=/opt/mendix \
java -Duser.home=$HOME -jar /opt/mendix/runtime/launcher/runtimelauncher.jar /opt/mendix/app &
MXRUNTIME_PID=$!

if ! ${BUILDPACK_INIT}/start.sh; then
  echo "Startup failed"
  shutdown_runtime
  exit 1
fi

wait $MXRUNTIME_PID
trap - SIGINT SIGTERM
wait $MXRUNTIME_PID

exit $EXITCODE
