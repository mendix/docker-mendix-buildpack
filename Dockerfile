# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
#
# Author: Mendix Digital Ecosystems, digitalecosystems@mendix.com
# Version: 1.0

# FROM cloudfoundry/cflinuxfs 2
FROM debian:jessie-backports
MAINTAINER Mendix Digital Ecosystems <digitalecosystems@mendix.com>

RUN apt-key adv --fetch-keys http://packages.mendix.com/mendix-debian-archive-key.asc
RUN echo "deb http://packages.mendix.com/platform/debian/ jessie main" > /etc/apt/sources.list.d/mendix.list

RUN apt-get update && apt-get install -y --no-install-recommends m2ee-tools openjdk-8-jre-headless postgresql-client procps netcat && apt-get clean

RUN mkdir -p /opt/mendix

RUN useradd -ms /bin/bash mendix

COPY start.sh /start.sh
RUN setfacl -m u:mendix:x /start.sh
# RUN chmod +x /start.sh

COPY m2ee.experimental /usr/bin/m2ee

USER mendix
WORKDIR /home/mendix

RUN mkdir .m2ee data model runtimes web buildpack && cd data && mkdir database files model-upload log tmp

COPY m2ee.yaml .m2ee/m2ee.yaml

# Run CF Build-pack here
RUN wget https://github.com/mendix/cf-mendix-buildpack/archive/master.tar.gz | tar -v -C /home/mendix/buildpack -xz


ENV MXDATA /home/mendix/data

EXPOSE 9000

ENTRYPOINT ["/start.sh"]
