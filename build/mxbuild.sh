#!/bin/sh
set -e

export JDK_HOME=/etc/alternatives/java_sdk

# Choose if mxbuild should run directly or from mono
MXBUILD_COMMAND=/opt/mendix/modeler/mxbuild
if [ $DOTNET_VERSION = "mono520" ]; then
    MXBUILD_COMMAND="mono /opt/mendix/modeler/mxbuild.exe"
fi

# Run MxBuild
cd /opt/mendix/home
$MXBUILD_COMMAND \
    --target=package \
    --java-home=${JDK_HOME} --java-exe-path=${JDK_HOME}/bin/java \
    --model-version=${MODEL_VERSION} \
    --output=/opt/mendix/home/output.mda /workdir/project/*.mpr

# Extract MDA
mkdir -p /workdir/mendix/app 
cd /workdir/mendix/app && jar xvf /opt/mendix/home/output.mda

# Set permissions for init scripts
cp -R /workdir/init /workdir/mendix/init
chown -R 1001:0 /workdir/mendix/init
chmod uga=rx /workdir/mendix/init /workdir/mendix/init/*.sh /workdir/mendix/init/init.d /workdir/mendix/init/init.d/*
