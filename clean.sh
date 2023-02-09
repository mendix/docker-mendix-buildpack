#!/bin/sh
set -e

LABELS="buildpack=mendix"

CONTAINERS=$(docker container ls -a -q --filter "label=${LABELS}")
if [ ! -z "$CONTAINERS" ]; then 
    docker container stop $CONTAINERS
fi

docker container prune --force --filter "label=${LABELS}"
rm -f app.tar
