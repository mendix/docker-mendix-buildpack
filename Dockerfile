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
   curl -fsSL https://github.com/mendix/cf-mendix-buildpack/archive/${CF_BUILDPACK}.tar.gz | tar xz -C /opt/mendix/buildpack --strip-components 1 &&\
   chgrp -R 0 /opt/mendix &&\
   chmod -R g=u  /opt/mendix

# Copy python scripts which execute the buildpack (exporting the VCAP variables)
COPY scripts/compilation scripts/git /opt/mendix/buildpack/

# Copy project model/sources
COPY $BUILD_PATH /opt/mendix/build

# Add the buildpack modules
ENV PYTHONPATH "/opt/mendix/buildpack/lib/"

# Each comment corresponds to the script line:
# 1. Create cache directory and directory for dependencies which can be shared
# 2. Set permissions for compilation scripts
# 3. Navigate to buildpack directory
# 4. Call compilation script
# 5. Remove temporary files
# 6. Create symlink for java prefs used by CF buildpack
# 7. Update ownership of /opt/mendix so that the app can run as a non-root user
# 8. Update permissions of /opt/mendix so that the app can run as a non-root user
RUN mkdir -p /tmp/buildcache /var/mendix/build /var/mendix/build/.local &&\
    chmod +rx /opt/mendix/buildpack/compilation /opt/mendix/buildpack/git &&\
    cd /opt/mendix/buildpack &&\
    ./compilation /opt/mendix/build /tmp/buildcache &&\
    rm -fr /tmp/buildcache /tmp/javasdk /tmp/opt /tmp/downloads /opt/mendix/buildpack/compilation /opt/mendix/buildpack/git &&\
    ln -s /opt/mendix/.java /opt/mendix/build &&\
    chgrp -R 0 /opt/mendix /var/mendix &&\
    chmod -R g=u /opt/mendix /var/mendix

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

# Copy jre from build container
COPY --from=builder /var/mendix/build/.local/usr /opt/mendix/build/.local/usr

# Copy Mendix Runtime from build container
COPY --from=builder /var/mendix/build/runtimes /opt/mendix/build/runtimes

# Copy build artifacts from build container
COPY --from=builder /opt/mendix /opt/mendix

WORKDIR /opt/mendix/build

USER 1001

ENV HOME "/opt/mendix/build"

# Expose nginx port
ENV PORT 8080
EXPOSE $PORT

ENTRYPOINT ["/opt/mendix/build/startup","/opt/mendix/buildpack/start.py"]
