# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
#
# Author: Mendix Digital Ecosystems, digitalecosystems@mendix.com
# Version: 2.0.0
ARG ROOTFS_IMAGE=mendix/rootfs:bionic

# Build stage
FROM ${ROOTFS_IMAGE} AS builder

# Build-time variables
ARG BUILD_PATH=project
ARG DD_API_KEY
# CF buildpack version
ARG CF_BUILDPACK=master

# Each comment corresponds to the script line:
# 1. Create all directories needed by scripts
# 2. Download CF buildpack
# 4. Update ownership of /opt/mendix so that the app can run as a non-root user
# 5. Update permissions of /opt/mendix so that the app can run as a non-root user
RUN mkdir -p /opt/mendix/buildpack /opt/mendix/build &&\
   echo "CF Buildpack version ${CF_BUILDPACK}" &&\
   curl -fsSL https://github.com/mendix/cf-mendix-buildpack/archive/${CF_BUILDPACK}.tar.gz | tar xvz -C /opt/mendix/buildpack --strip-components 1 &&\
   chgrp -R 0 /opt/mendix &&\
   chmod -R g=u  /opt/mendix

# Copy python scripts which execute the buildpack (exporting the VCAP variables)
COPY scripts/compilation scripts/git /opt/mendix/buildpack/

# Copy cleanupjdk script which will delete the JDK after a successful build
COPY scripts/cleanupjdk /opt/mendix/buildpack/bin

# Copy project model/sources
COPY $BUILD_PATH /opt/mendix/build

# Add the buildpack modules
ENV PYTHONPATH "/opt/mendix/buildpack/lib/"

# Each comment corresponds to the script line:
# 1. Create cache directory
# 2. Set permissions for compilation scripts
# 3. Navigate to buildpack directory
# 4. Call compilation script
# 5. Remove the JDK which is not needed after the build completes
# 6. Remove temporary files
# 7. Create symlink for java prefs used by CF buildpack
# 8. Update ownership of /opt/mendix so that the app can run as a non-root user
# 9. Update permissions of /opt/mendix so that the app can run as a non-root user
RUN mkdir -p /tmp/buildcache &&\
    chmod +rx /opt/mendix/buildpack/compilation /opt/mendix/buildpack/git /opt/mendix/buildpack/bin/cleanupjdk &&\
    cd /opt/mendix/buildpack &&\
    ./compilation /opt/mendix/build /tmp/buildcache &&\
    bin/cleanupjdk /opt/mendix/build /tmp/buildcache &&\
    rm -fr /tmp/buildcache /tmp/javasdk /tmp/opt bin/cleanupjdk compilation &&\
    ln -s /opt/mendix/.java /opt/mendix/build &&\
    chgrp -R 0 /opt/mendix &&\
    chmod -R g=u /opt/mendix

FROM ${ROOTFS_IMAGE}
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Allow the root group to modify /etc/passwd so that the startup script can update the non-root uid
RUN chmod g=u /etc/passwd

# Add the buildpack modules
ENV PYTHONPATH "/opt/mendix/buildpack/lib/"

# Copy start scripts
COPY scripts/startup scripts/vcap_application.json /opt/mendix/build/

# Each comment corresponds to the script line:
# 1. Make the startup script executable
# 2. Update ownership of /opt/mendix so that the app can run as a non-root user
# 3. Update permissions of /opt/mendix so that the app can run as a non-root user
RUN chmod +rx /opt/mendix/build/startup &&\
    chgrp -R 0 /opt/mendix &&\
    chmod -R g=u /opt/mendix

# Copy build artifacts from build container
COPY --from=builder /opt/mendix /opt/mendix

WORKDIR /opt/mendix/build

USER 1001

ENV HOME "/opt/mendix/build"

# Expose nginx port
ENV PORT 8080
EXPOSE $PORT

ENTRYPOINT ["/opt/mendix/build/startup","/opt/mendix/buildpack/start.py"]
