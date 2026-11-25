# Dockerfile that can convert an MPR project into an MDA file.
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest

# Set the locale
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# Set the user ID
ARG USER_UID=11001
ENV USER_UID=${USER_UID}

# Install common prerequisites
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm &&\
    microdnf update -y && \
    microdnf install -y glibc-langpack-en openssl fontconfig tzdata-java libgdiplus libicu tar gzip jq \
    java-11-openjdk-devel java-17-openjdk-devel java-21-openjdk-devel && \
    microdnf clean all && rm -rf /var/cache/yum

# Create user (for non-OpenShift clusters)
RUN echo "mendix:x:${USER_UID}:${USER_UID}:mendix user:/workdir:/sbin/nologin" >> /etc/passwd

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
