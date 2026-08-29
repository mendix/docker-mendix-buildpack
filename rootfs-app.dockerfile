# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
FROM registry.access.redhat.com/ubi9-minimal:latest
#This version does a full build originating from the Ubuntu Docker images
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Set the locale
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8

# install dependencies & remove package lists
RUN microdnf update -y && \
    microdnf module enable nginx:1.26 -y && \
    microdnf install -y glibc-langpack-en python311 openssl nginx nginx-mod-stream java-11-openjdk-headless java-17-openjdk-headless java-21-openjdk-headless java-25-openjdk-headless tzdata-java fontconfig binutils && \
    microdnf clean all && rm -rf /var/cache/yum

# Set the user ID
ARG USER_UID=11001

# Set nginx permissions
RUN touch /run/nginx.pid && \
    chown -R ${USER_UID}:0 /var/log/nginx /var/lib/nginx /run &&\
    chmod -R g=u /var/log/nginx /var/lib/nginx /run

# Set python alias to Python 3.11 to avoid using Java version
RUN if [ -f /usr/bin/python ] ; then rm /usr/bin/python; fi &&\
    if [ -f /usr/bin/python3 ] ; then rm /usr/bin/python3 ; fi &&\
    ln -s /usr/bin/python3.11 /usr/bin/python3 &&\
    ln -s /usr/bin/python3.11 /usr/bin/python

# Create vcap home directory for Datadog configuration
RUN mkdir -p /home /app/log /opt/mendix/build /opt/datadog-agent/run &&\
    ln -s /opt/mendix/build /home/vcap &&\
    chown -R ${USER_UID}:0 /home/vcap /opt/datadog-agent/run /app/log &&\
    chmod -R g=u /home/vcap /opt/datadog-agent/run /app/log

# Copy Cloud Foundry emulation scripts
COPY --chmod=0755 --chown=0:0 scripts/host /usr/local/bin/

# Prepare home directory and set permissions
RUN mkdir -p /opt/mendix &&\
    chown -R ${USER_UID}:0 /opt/mendix &&\
    chmod -R g=u /opt/mendix &&\
    ln -s /opt/mendix/.java /root

# Create user (for non-OpenShift clusters)
RUN echo "mendix:x:${USER_UID}:${USER_UID}:mendix user:/opt/mendix/build:/sbin/nologin" >> /etc/passwd
