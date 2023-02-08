# Prepare ubi-micro image with base packages
FROM registry.access.redhat.com/ubi8/ubi as builder

ARG JAVA_VERSION
ARG USER_UID=1001
ARG USER_HOME=/opt/mendix/home

# Mount ubi-micro rootfs
COPY --from=registry.access.redhat.com/ubi8/ubi-micro / /mnt/rootfs

# Base layer: prerequisites

# java for the runtime
# fontconfig for generating Excel reports and other documents
# curl to communicate with the Mendix Runtime
# jq for the init scripts
RUN dnf install \
    --installroot /mnt/rootfs --setopt install_weak_deps=false --nodocs -y \
    java-${JAVA_VERSION}-openjdk-headless fontconfig curl jq -y && \
    dnf clean all --installroot /mnt/rootfs &&\
    rm -rf /mnt/rootfs/var/cache/* /mnt/rootfs/var/log/dnf* /mnt/rootfs/var/log/yum.*

# Mendix directories
RUN mkdir -p /mnt/rootfs/opt/mendix/app && \
    mkdir -p /mnt/rootfs/opt/mendix/app/data/database /mnt/rootfs/opt/mendix/app/data/files /mnt/rootfs/opt/mendix/app/data/model-upload /mnt/rootfs/opt/mendix/app/data/tmp && \
    mkdir -p /mnt/rootfs/opt/mendix/app/.java/.userPrefs

# Create user (for non-OpenShift clusters) and set permissions
# chown to user 1001 for non-OpenShift clusters
# set group 0 (root) for OpenShift (we don't know what the runtime UID will be)
RUN echo "mendix:x:${USER_UID}:${USER_UID}:mendix user:${USER_HOME}:/sbin/nologin" >> /mnt/rootfs/etc/passwd && \
    chown -R ${USER_UID}:0 /mnt/rootfs/opt/mendix/app && \
    chmod -R g=u /mnt/rootfs/opt/mendix/app

# Download the Mendix Runtime
FROM registry.access.redhat.com/ubi8/ubi as downloader

ARG MX_VERSION
ARG DOWNLOAD_URL=https://download.mendix.com/runtimes/

# Set runtime owner to root (prevent modifications during runtime)
RUN cd /opt && \
    curl -sL "${DOWNLOAD_URL}mendix-${MX_VERSION}.tar.gz" | tar -xz && \
    chown -R 0:0 /opt/${MX_VERSION}

# Create app image
FROM registry.access.redhat.com/ubi8/ubi-micro

ARG JAVA_VERSION
ARG USER_UID=1001
ARG USER_HOME=/opt/mendix/home

# Set the locale
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Set the user ID and home path
ENV USER_UID=$USER_UID \
    HOME=$USER_HOME

# Mendix Runtime layer: MxRuntime matching the app version
ARG MX_VERSION

# Copy base OS dependencies
COPY --from=builder /mnt/rootfs/ /

# Copy downloaded runtime
COPY --from=downloader /opt/${MX_VERSION} /opt/mendix/

# Copy the build artifacts
ADD app.tar /opt/

# App container configuration
USER ${USER_UID}
EXPOSE 8080

ENV BUILD_PACK_INIT=/opt/mendix/init

CMD ["/opt/mendix/init/mxruntime.sh"]
