# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
#
# Author: Mendix Digital Ecosystems, digitalecosystems@mendix.com
# Version: 2.0.0
ARG ROOTFS_IMAGE=mendix/rootfs

FROM ${ROOTFS_IMAGE}
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Build-time variables
ARG BUILD_PATH=project
ARG DD_API_KEY
# CF buildpack version
ARG CF_BUILDPACK=master

# Each comment corresponds to the script line:
# 1. Create all directories needed by scripts
# 2. Create mendix user with home directory at /opt/mendix/build
# 4. Download CF buildpack
# 5. Update the owner and group for /opt/mendix so that the app can run as a non-root user
# 6. Update permissions for /opt/mendix so that the app can run as a non-root user
# 7. Allow the root group to modify /etc/passwd so that the startup script can update the non-root uid
RUN mkdir -p /opt/mendix/buildpack /opt/mendix/build &&\
   useradd -r -g root -d /opt/mendix/build mendix &&\
   echo "CF Buildpack version ${CF_BUILDPACK}" &&\
   wget -qO- https://github.com/mendix/cf-mendix-buildpack/archive/${CF_BUILDPACK}.tar.gz | tar xvz -C /opt/mendix/buildpack --strip-components 1 &&\
   chown -R mendix:root /opt/mendix &&\
   chmod -R g+rwX /opt/mendix &&\
   chmod g+w /etc/passwd

# Copy python scripts which execute the buildpack (exporting the VCAP variables)
COPY --chown=mendix:root scripts/compilation /opt/mendix/buildpack
# Copy project model/sources
COPY --chown=mendix:root $BUILD_PATH /opt/mendix/build

# Add the buildpack modules
ENV PYTHONPATH "/opt/mendix/buildpack/lib/"

# Each comment corresponds to the script line:
# 1. Create cache directory
# 2. Call compilation script
# 3. Remove temporary folders
# 4. Create symlink for java prefs used by CF buildpack
# 5. Update ownership of /opt/mendix so that the app can run as a non-root user
# 6. Update permissions for /opt/mendix/build so that the app can run as a non-root user
WORKDIR /opt/mendix/buildpack
RUN mkdir -p /tmp/buildcache &&\
    "/opt/mendix/buildpack/compilation" /opt/mendix/build /tmp/buildcache &&\
    rm -fr /tmp/buildcache /tmp/javasdk /tmp/opt &&\
    ln -s /opt/mendix/.java /opt/mendix/build &&\
    chown -R mendix:root /opt/mendix &&\
    chmod -R g+rwX /opt/mendix

# Copy start scripts
COPY --chown=mendix:root scripts/startup /opt/mendix/build
COPY --chown=mendix:root scripts/vcap_application.json /opt/mendix/build
WORKDIR /opt/mendix/build

USER mendix

ENV HOME "/opt/mendix/build"

# Expose nginx port
ENV PORT 8080
EXPOSE $PORT

ENTRYPOINT ["/opt/mendix/build/startup","/opt/mendix/buildpack/start.py"]
