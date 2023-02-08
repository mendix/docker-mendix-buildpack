# Prepare ubi-minimal image with base packages
FROM registry.access.redhat.com/ubi8/ubi as builder

ARG JAVA_VERSION
ARG DOTNET_VERSION
ARG USER_UID=1001
ARG USER_HOME=/opt/mendix/home

# Add Mono repository
COPY --chown=0:0 mono/xamarin.gpg /etc/pki/rpm-gpg/RPM-GPG-KEY-mono-centos8-stable
COPY --chown=0:0 mono/mono-centos8-stable.repo /etc/yum.repos.d/mono-centos8-stable.repo
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-mono-centos8-stable

# Mount ubi-micro rootfs
COPY --from=registry.access.redhat.com/ubi8/ubi-micro / /mnt/rootfs

# Select mono or .net libraries
RUN if [ $DOTNET_VERSION = "mono520" ]; then \
        DOTNET_LIBS="mono-core-5.20.1.34 libgdiplus0 libicu"; \
        cp /etc/pki/rpm-gpg/RPM-GPG-KEY-mono-centos8-stable /mnt/rootfs/etc/pki/rpm-gpg/; \
        cp /etc/yum.repos.d/mono-centos8-stable.repo /mnt/rootfs/etc/yum.repos.d/; \
    elif [ $DOTNET_VERSION = "dotnet6" ]; then \
        DOTNET_LIBS="dotnet-runtime-6.0 libgdiplus"; \
        rm /etc/yum.repos.d/mono-centos8-stable.repo; \
        dnf install --setopt install_weak_deps=false --nodocs --installroot /mnt/rootfs -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm; \
        cp /mnt/rootfs/etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-8 /etc/pki/rpm-gpg/; \
    else \
        echo "Unsupported .NET version $DOTNET_VERSION"; \
    fi &&\
    echo $DOTNET_LIBS > /tmp/dotnet-libs

# Install JDK and .NET
RUN DOTNET_LIBS=$(cat /tmp/dotnet-libs | head -n 1) &&\
    dnf install \
    --installroot /mnt/rootfs --setopt install_weak_deps=false --nodocs -y \
    java-${JAVA_VERSION}-openjdk-devel $DOTNET_LIBS &&\
    dnf clean all --installroot /mnt/rootfs &&\
    rm -rf /mnt/rootfs/var/cache/* /mnt/rootfs/var/log/dnf* /mnt/rootfs/var/log/yum.*

# Create user (for non-OpenShift clusters) and set permissions
# chown to user 1001 for non-OpenShift clusters
# set group 0 (root) for OpenShift (we don't know what the runtime UID will be)
RUN echo "mendix:x:${USER_UID}:0:mendix user:${USER_HOME}:/sbin/nologin" >> /mnt/rootfs/etc/passwd &&\
    mkdir -p /mnt/rootfs/${USER_HOME} &&\
    chown ${USER_UID}:0 /mnt/rootfs/${USER_HOME}

# Download MxBuild
FROM registry.access.redhat.com/ubi8/ubi as downloader

ARG MX_VERSION
ARG DOTNET_VERSION
ARG DOWNLOAD_URL=https://download.mendix.com/runtimes/

# Download MxBuild
RUN mkdir -p /mxbuild
RUN ARCH=$(arch) && \
    if [ $DOTNET_VERSION = "mono520" ]; then \
        MXBUILD_DOWNLOAD_PREFIX=""; \
    elif [ $DOTNET_VERSION = "dotnet6" ] && [ $ARCH = "aarch64" ]; then \
        MXBUILD_DOWNLOAD_PREFIX="arm64-"; \
    elif [ $DOTNET_VERSION = "dotnet6" ] && [ $ARCH = "x86_64" ]; then \
        MXBUILD_DOWNLOAD_PREFIX="net6-"; \
    else \
        echo "Unsupported .NET $DOTNET_VERSION or architecture $ARCH"; \
    fi &&\
    curl -sL "${DOWNLOAD_URL}${MXBUILD_DOWNLOAD_PREFIX}mxbuild-${MX_VERSION}.tar.gz" | tar -xz -C /mxbuild &&\
    chown -R 0:0 /mxbuild

# Create MxBuild image
FROM registry.access.redhat.com/ubi8/ubi-micro

ARG USER_UID=1001
ARG USER_HOME=/opt/mendix/home
ARG DOTNET_VERSION

ENV HOME=$USER_HOME
ENV DOTNET_VERSION=${DOTNET_VERSION}

# Copy base OS dependencies
COPY --from=builder /mnt/rootfs/ /

COPY mxbuild.sh /usr/local/bin/

# Copy downloaded MxBuild
COPY --from=downloader /mxbuild /opt/mendix

CMD /usr/local/bin/mxbuild.sh

USER $USER_UID
