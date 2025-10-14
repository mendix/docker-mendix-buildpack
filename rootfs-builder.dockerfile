# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
FROM registry.access.redhat.com/ubi9/ubi-minimal:latest
#This version does a full build originating from the Ubuntu Docker images
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Set the locale
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# CF buildpack version
ARG CF_BUILDPACK=v5.0.26
# CF buildpack download URL
ARG CF_BUILDPACK_URL=https://github.com/mendix/cf-mendix-buildpack/releases/download/${CF_BUILDPACK}/cf-mendix-buildpack.zip

# Allow specification of debugging options
ARG BUILDPACK_XTRACE

# install dependencies & remove package lists
RUN microdnf update -y && \
    microdnf module enable nginx:1.24 -y && \
    microdnf install -y wget glibc-langpack-en python311 openssl tar gzip unzip libpq nginx nginx-mod-stream binutils fontconfig findutils java-11-openjdk-headless java-17-openjdk-headless java-21-openjdk-headless && \
    microdnf remove -y /usr/bin/python && \
    microdnf clean all && rm -rf /var/cache/yum

# Set the user ID
ARG USER_UID=11001
ENV USER_UID=${USER_UID}

# Set nginx permissions
RUN touch /run/nginx.pid && \
    chown -R ${USER_UID}:0 /var/log/nginx /var/lib/nginx /run &&\
    chmod -R g=u /var/log/nginx /var/lib/nginx /run

# Set python alias to Python 3.11 to avoid using Java version
RUN if [ -f /usr/bin/python ] ; then rm /usr/bin/python; fi &&\
    if [ -f /usr/bin/python3 ] ; then rm /usr/bin/python3 ; fi &&\
    ln -s /usr/bin/python3.11 /usr/bin/python3 &&\
    ln -s /usr/bin/python3.11 /usr/bin/python

# Download and prepare CF Buildpack

# Switch CF Buildpack to use Python 3.10+ compatibility
ENV CF_STACK cflinuxfs4

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
COPY scripts/compilation.py /opt/mendix/buildpack/

# Install the buildpack Python dependencies
RUN PYTHON_BUILD_RPMS="python3.11-pip python3.11-devel libffi-devel gcc" && \
    microdnf install -y $PYTHON_BUILD_RPMS && \
    mkdir -p  /home/vcap/.local/bin/ && \
    if [ ! -f /home/vcap/.local/bin/pip ] ; then ln -s /usr/bin/pip3.11 /home/vcap/.local/bin/pip ; fi && \
    rm /opt/mendix/buildpack/vendor/wheels/* && \
    chmod +rx /opt/mendix/buildpack/bin/bootstrap-python && /opt/mendix/buildpack/bin/bootstrap-python /opt/mendix/buildpack /tmp/buildcache && \
    microdnf remove -y $PYTHON_BUILD_RPMS && microdnf clean all && rm -rf /var/cache/yum

# Add the buildpack modules
ENV PYTHONPATH "$PYTHONPATH:/opt/mendix/buildpack/lib/:/opt/mendix/buildpack/:/opt/mendix/buildpack/lib/python3.11/site-packages"
