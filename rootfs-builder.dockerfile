# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
FROM registry.access.redhat.com/ubi8/ubi-minimal:latest
#This version does a full build originating from the Ubuntu Docker images
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Set the locale
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# install dependencies & remove package lists
RUN rpm -ivh https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm &&\
    microdnf update -y && \
    microdnf module enable nginx:1.20 -y && \
    microdnf install -y wget curl glibc-langpack-en python3 python3-setuptools openssl libgdiplus tar gzip unzip libpq nginx nginx-mod-stream binutils fontconfig && \
    microdnf clean all && rm -rf /var/cache/yum

# Set nginx permissions
RUN touch /run/nginx.pid && \
    chown -R 1001:0 /var/log/nginx /var/lib/nginx /run/nginx.pid &&\
    chmod -R g=u /var/log/nginx /var/lib/nginx /run/nginx.pid

# Pretend to be Ubuntu to bypass CF Buildpack's check
RUN rm /etc/*-release && echo 'Ubuntu release 18.04 (Bionic)' > /etc/debian-release

# Set python alias to python3 (required for Datadog)
RUN alternatives --set python /usr/bin/python3

