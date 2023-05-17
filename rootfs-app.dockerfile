# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
FROM --platform=linux/amd64 registry.access.redhat.com/ubi8/ubi-minimal:latest
#This version does a full build originating from the Ubuntu Docker images
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Set the locale
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# install dependencies & remove package lists
RUN microdnf update -y && \
    microdnf module enable nginx:1.20 -y && \
    microdnf install -y glibc-langpack-en python36 openssl nginx nginx-mod-stream fontconfig && \
    microdnf clean all && rm -rf /var/cache/yum

# Set nginx permissions
RUN touch /run/nginx.pid && \
    chown -R 1001:0 /var/log/nginx /var/lib/nginx /run &&\
    chmod -R g=u /var/log/nginx /var/lib/nginx /run

# Set python alias to python3 (required for Datadog)
RUN alternatives --set python /usr/bin/python3

# Set the user ID
ARG USER_UID=1001

# Create user (for non-OpenShift clusters)
RUN echo "mendix:x:${USER_UID}:${USER_UID}:mendix user:/opt/mendix/build:/sbin/nologin" >> /etc/passwd
