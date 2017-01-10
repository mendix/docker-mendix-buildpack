# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
#
# Author: Mendix Digital Ecosystems, digitalecosystems@mendix.com
# Version: 1.0

FROM cloudfoundry/cflinuxfs2
MAINTAINER Mendix Digital Ecosystems <digitalecosystems@mendix.com>

# Add Mendix repository
RUN apt-key adv --fetch-keys http://packages.mendix.com/mendix-debian-archive-key.asc
RUN echo "deb http://packages.mendix.com/platform/debian/ jessie main" > \
    /etc/apt/sources.list.d/mendix.list

# Install m2ee tools, jre, postgres client and other utils
RUN apt-get update && apt-get install -y --no-install-recommends m2ee-tools \
    postgresql-client procps netcat && apt-get clean

# Create tmp folder to store the output of compilation
RUN mkdir -p /tmp

# Create mendix user
RUN useradd -ms /bin/bash mendix

# Give mendix user write access to the tmp folder
RUN chown -R mendix /tmp

# Login as mendix user
# USER mendix
# WORKDIR /home/mendix

# Default build-time variables
ARG BUID_PATH=build
ARG CACHE_PATH=cache
ARG DATABASE_URL=postgres://mendix:mendix@127.0.0.1:5432/mendix

# Checkout CF Build-pack here
RUN mkdir buildpack && \
  (wget -qO- https://github.com/mendix/cf-mendix-buildpack/archive/master.tar.gz \
  | tar xvz -C buildpack --strip-components 1)

# Add the buildpack modules
ENV PYTHONPATH "$PYTHONPATH:/buildpack/lib/"

# Create the build destination
RUN mkdir build cache
COPY $BUID_PATH build/

# Compile the application source code
RUN ["buildpack/bin/compile", "/build/", "/cache/"]


# Expose nginx port
EXPOSE 80

# Start up application
ENTRYPOINT ["python", "buildpack/start.py"]
