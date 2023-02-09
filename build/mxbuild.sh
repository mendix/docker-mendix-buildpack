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
cd /workdir/app && jar xvf /opt/mendix/home/output.mda
