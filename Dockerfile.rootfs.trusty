# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
FROM ubuntu:trusty
#This version does a full build originating from the Ubuntu Docker images
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Set the locale
RUN locale-gen en_US.UTF-8  
ENV LANG en_US.UTF-8  
ENV LC_ALL en_US.UTF-8 

# When doing a full build: install dependencies & remove package lists
RUN apt-get -q -y update && \
 DEBIAN_FRONTEND=noninteractive apt-get upgrade -q -y && \
 DEBIAN_FRONTEND=noninteractive apt-get install -q -y python3 wget curl libgdiplus libpq5 && \
 rm -rf /var/lib/apt/lists/*