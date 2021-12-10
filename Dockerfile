# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
#
# Author: Mendix Digital Ecosystems, digitalecosystems@mendix.com
# Version: 2.1.0

# Build stage
FROM mendix/rootfs:bionic AS builder

# (cut) move down for ocp3 (have builder first)
ARG ROOTFS_IMAGE=mendix/rootfs:ubi8
ARG BUILDER_ROOTFS_IMAGE=mendix/rootfs:bionic

# Build-time variables
ARG BUILD_PATH=project
ARG DD_API_KEY
# CF buildpack version
ARG CF_BUILDPACK=v4.20.0
# CF buildpack download URL
ARG CF_BUILDPACK_URL=https://github.com/mendix/cf-mendix-buildpack/releases/download/${CF_BUILDPACK}/cf-mendix-buildpack.zip

# Exclude the logfilter binary by default
ARG EXCLUDE_LOGFILTER=true

# Allow specification of alternative BLOBSTORE location and debugging
ARG BLOBSTORE
ARG BUILDPACK_XTRACE

# Set the user ID
ARG USER_UID=1001

# Each comment corresponds to the script line:
# 1. Create all directories needed by scripts
# 2. Download CF buildpack
# 3. Extract CF buildpack
# 4. Delete CF buildpack zip archive
# 5. Update ownership of /opt/mendix so that the app can run as a non-root user
# 6. Update permissions of /opt/mendix so that the app can run as a non-root user
RUN mkdir -p /opt/mendix/buildpack /opt/mendix/build &&\
    ln -s /root /home/vcap &&\
    echo "Downloading CF Buildpack from ${CF_BUILDPACK_URL}" &&\
    curl -fsSL ${CF_BUILDPACK_URL} -o /tmp/cf-mendix-buildpack.zip && \
    python3 -m zipfile -e /tmp/cf-mendix-buildpack.zip /opt/mendix/buildpack/ &&\
    rm /tmp/cf-mendix-buildpack.zip &&\
    chown -R ${USER_UID}:0 /opt/mendix &&\
    chmod -R g=u /opt/mendix

# Copy python scripts which execute the buildpack (exporting the VCAP variables)
COPY scripts/compilation scripts/git /opt/mendix/buildpack/

# Copy project model/sources
COPY $BUILD_PATH /opt/mendix/build

# Install the buildpack Python dependencies
RUN chmod +rx /opt/mendix/buildpack/bin/bootstrap-python && /opt/mendix/buildpack/bin/bootstrap-python /opt/mendix/buildpack /tmp/buildcache

# Add the buildpack modules
ENV PYTHONPATH "$PYTHONPATH:/opt/mendix/buildpack/lib/:/opt/mendix/buildpack/:/opt/mendix/buildpack/lib/python3.6/site-packages/"

# Use nginx supplied by the base OS
ENV NGINX_CUSTOM_BIN_PATH=/usr/sbin/nginx

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
    chmod +rx /opt/mendix/buildpack/compilation /opt/mendix/buildpack/git /opt/mendix/buildpack/buildpack/stage.py &&\
    cd /opt/mendix/buildpack &&\
    ./compilation /opt/mendix/build /tmp/buildcache &&\
    rm -fr /tmp/buildcache /tmp/javasdk /tmp/opt /tmp/downloads /opt/mendix/buildpack/compilation /opt/mendix/buildpack/git &&\
    ln -s /opt/mendix/.java /opt/mendix/build &&\
    chown -R ${USER_UID}:0 /opt/mendix /var/mendix &&\
    chmod -R g=u /opt/mendix /var/mendix

FROM mendix/rootfs:ubi8
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Uninstall build-time dependencies to remove potentially vulnerable libraries
ARG UNINSTALL_BUILD_DEPENDENCIES=true

# Set the user ID
ARG USER_UID=1001
# Set the home path
ENV HOME=/opt/mendix/build

# Allow the user group to modify /etc/passwd so that OpenShift 3 randomized UIDs are supported by CF Buildpack 
RUN chmod g=u /etc/passwd &&\
    chown ${USER_UID}:0 /etc/passwd

# Uninstall Ubuntu packages which are only required during build time
RUN if [ "$UNINSTALL_BUILD_DEPENDENCIES" = "true" ] && grep -q ubuntu /etc/os-release ; then\
        DEBIAN_FRONTEND=noninteractive apt-mark manual libfontconfig1 && \
        DEBIAN_FRONTEND=noninteractive apt-get remove --purge --auto-remove -q -y wget curl libgdiplus ; \
    fi

# Add the buildpack modules
ENV PYTHONPATH "/opt/mendix/buildpack/lib/:/opt/mendix/buildpack/:/opt/mendix/buildpack/lib/python3.6/site-packages/"

# Copy start scripts
COPY scripts/startup scripts/vcap_application.json /opt/mendix/build/

# Create vcap home directory for Datadog configuration
RUN mkdir -p /home/vcap /opt/datadog-agent/run &&\
    chown -R ${USER_UID}:0 /home/vcap /opt/datadog-agent/run &&\
    chmod -R g=u /home/vcap /opt/datadog-agent/run

# Each comment corresponds to the script line:
# 1. Make the startup script executable
# 2. Update ownership of /opt/mendix so that the app can run as a non-root user
# 3. Update permissions of /opt/mendix so that the app can run as a non-root user
# 4. Ensure that running Java 8 as root will still be able to load offline licenses
RUN chmod +rx /opt/mendix/build/startup &&\
    chown -R ${USER_UID}:0 /opt/mendix &&\
    chown -R ${USER_UID}:0 /etc/nginx &&\
    chmod -R 777 /opt/mendix &&\
    chmod -R 777 /etc/nginx &&\
    ln -s /opt/mendix/.java /root
    
RUN rm /run/nginx.pid || true

USER ${USER_UID}

# Copy jre from build container
COPY --from=builder /var/mendix/build/.local/usr /opt/mendix/build/.local/usr

# Copy Mendix Runtime from build container
COPY --from=builder /var/mendix/build/runtimes /opt/mendix/build/runtimes

# Copy build artifacts from build container
COPY --from=builder /opt/mendix /opt/mendix

# Use nginx supplied by the base OS
ENV NGINX_CUSTOM_BIN_PATH=/usr/sbin/nginx

WORKDIR /opt/mendix/build

# Expose nginx port
ENV PORT 8080
EXPOSE $PORT

ENTRYPOINT ["/opt/mendix/build/startup","/opt/mendix/buildpack/buildpack/start.py"]
