#!/bin/sh
set -e

MPR_FILE=/workdir/project/*.mpr
if [ ! -f $MPR_FILE ]; then
    echo "MPR not found" >&2
    exit 1
fi

PROJECT_VERSION=$(sqlite3 $MPR_FILE "SELECT _ProductVersion FROM _MetaData;")
if [ -z $PROJECT_VERSION ]; then
    echo "No version data in MPR file" >&2
    exit 1
fi
echo -n $PROJECT_VERSION
