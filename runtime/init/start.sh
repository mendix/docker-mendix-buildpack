#!/bin/sh
set -e

echo "Running Mendix Runtime startup scripts"
for script in ${BUILDPACK_INIT}/init.d/S*.sh
do
    $script
done
