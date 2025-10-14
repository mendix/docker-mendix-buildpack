# Dockerfile that can convert an MPR project into an MDA file.
FROM --platform=linux/amd64 registry.access.redhat.com/ubi8/ubi-minimal:latest

# Set the locale
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Set the user ID
ARG USER_UID=11001
ENV USER_UID=${USER_UID}

# Add mono repo
COPY --chown=0:0 mono/xamarin.gpg /etc/pki/rpm-gpg/RPM-GPG-KEY-mono-centos8-stable
COPY --chown=0:0 mono/mono-centos8-stable.repo /etc/yum.repos.d/mono-centos8-stable.repo

# Install mono and common prerequisites
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm &&\
    microdnf update -y && \
    microdnf install -y glibc-langpack-en openssl fontconfig tzdata-java mono-core-5.20.1.34 libgdiplus0 libicu tar jq \
    java-11-openjdk-devel java-17-openjdk-devel java-21-openjdk-devel && \
    microdnf clean all && rm -rf /var/cache/yum

# Download and extract MxBuild
ARG MXBUILD_DOWNLOAD_URL
RUN mkdir -p /opt/mendix && curl -sL $MXBUILD_DOWNLOAD_URL | tar -C /opt/mendix -xzf - --owner=root:0 --group=root:0 --mode='uga=rX'
COPY --chown=0:0 --chmod=0755 build /opt/mendix/build

# Prepare build context
ENV HOME /workdir
RUN mkdir -p /workdir/project /workdir/output /workdir/.local/share/Mendix &&\
    chown -R ${USER_UID}:${USER_UID} /workdir &&\
    chmod -R 755 /workdir

ENTRYPOINT ["/opt/mendix/build"]
