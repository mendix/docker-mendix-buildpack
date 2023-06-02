# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
FROM --platform=linux/amd64 registry.access.redhat.com/ubi8/ubi-minimal:latest
#This version does a full build originating from the Ubuntu Docker images
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Set the locale
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# CF buildpack version
ARG CF_BUILDPACK=v4.30.19
# CF buildpack download URL
# ARG CF_BUILDPACK_URL=https://github.com/mendix/cf-mendix-buildpack/releases/download/${CF_BUILDPACK}/cf-mendix-buildpack.zip
# Temporary workaround, remove before release
ARG CF_BUILDPACK_URL=https://github.com/jpastoor/cf-mendix-buildpack/archive/refs/heads/UPV4-2789_cflinuxfs4.zip

# Set the user ID
ARG USER_UID=1001
ENV USER_UID=${USER_UID}

# Allow specification of debugging options
ARG BUILDPACK_XTRACE

# Add mono repo
COPY --chown=0:0 scripts/mono/xamarin.gpg /etc/pki/rpm-gpg/RPM-GPG-KEY-mono-centos8-stable
COPY --chown=0:0 scripts/mono/mono-centos8-stable.repo /etc/yum.repos.d/mono-centos8-stable.repo

# install dependencies & remove package lists
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm &&\
    microdnf update -y && \
    microdnf module enable nginx:1.20 -y && \
    microdnf install -y wget curl glibc-langpack-en python311 openssl tar gzip unzip libpq nginx nginx-mod-stream binutils fontconfig findutils && \
    microdnf clean all && rm -rf /var/cache/yum

# Install RHEL alternatives to CF Buildpack dependencies
RUN microdnf install -y java-11-openjdk-headless java-11-openjdk-devel mono-core-5.20.1.34 libgdiplus0 libicu && \
    microdnf clean all && rm -rf /var/cache/yum

# Set nginx permissions
RUN touch /run/nginx.pid && \
    chown -R 1001:0 /var/log/nginx /var/lib/nginx /run/nginx.pid &&\
    chmod -R g=u /var/log/nginx /var/lib/nginx /run/nginx.pid

# Pretend to be Ubuntu to bypass CF Buildpack's check
RUN rm /etc/*-release && printf 'NAME="Ubuntu"\nID=ubuntu\nVersion="22.04 LTS (Jammy Jellyfish)"\nVERSION_CODENAME=jammy\n' > /etc/os-release

# Set python alias to python3 (required for Datadog)
RUN alternatives --set python /usr/bin/python3

# Download and prepare CF Buildpack

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
    # Temporary workaround, remove before release
    (mv /opt/mendix/buildpack/cf-mendix-buildpack-UPV4-2789_cflinuxfs4/* /opt/mendix/buildpack/cf-mendix-buildpack-UPV4-2789_cflinuxfs4/.* /opt/mendix/buildpack/ || true) && rmdir /opt/mendix/buildpack/cf-mendix-buildpack-UPV4-2789_cflinuxfs4 &&\
    rm /tmp/cf-mendix-buildpack.zip &&\
    chown -R ${USER_UID}:0 /opt/mendix &&\
    chmod -R g=u /opt/mendix

# Copy python scripts which execute the buildpack (exporting the VCAP variables)
COPY scripts/compilation.py scripts/git /opt/mendix/buildpack/

# Install the buildpack Python dependencies
RUN PYTHON_BUILD_RPMS="python3.11-pip python3.11-devel libffi-devel gcc" && \
    microdnf install -y $PYTHON_BUILD_RPMS && \
    chmod +rx /opt/mendix/buildpack/bin/bootstrap-python && /opt/mendix/buildpack/bin/bootstrap-python /opt/mendix/buildpack /tmp/buildcache && \
    microdnf remove -y $PYTHON_BUILD_RPMS && microdnf clean all && rm -rf /var/cache/yum

# Add the buildpack modules
ENV PYTHONPATH "$PYTHONPATH:/opt/mendix/buildpack/lib/:/opt/mendix/buildpack/:/opt/mendix/buildpack/lib/python3.11/site-packages/"
