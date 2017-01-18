# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
#
# Author: Mendix Digital Ecosystems, digitalecosystems@mendix.com
# Version: 1.0

FROM cloudfoundry/cflinuxfs2
MAINTAINER Mendix Digital Ecosystems <digitalecosystems@mendix.com>

# Default build-time variables
ARG BUID_PATH=build
ARG CACHE_PATH=cache
ARG VCAP_SERVICES
ARG VCAP_APPLICATION

# Copy the vcap-builder script (exports the VCAP variables)
COPY vcap_services.json /tmp
COPY vcap_application.json /tmp
COPY vcap-services-builder /tmp
WORKDIR /tmp

# Checkout CF Build-pack here
RUN export VCAP_SERVICES=$(./vcap-services-builder) && mkdir -p buildpack/.local && \
  (wget -qO- https://github.com/mendix/cf-mendix-buildpack/archive/master.tar.gz \
  | tar xvz -C buildpack --strip-components 1)

# Add the buildpack modules
ENV PYTHONPATH "/buildpack/lib/"

# Export VCAP_SERVICES
ENV VCAP_SERVICES $VCAP_SERVICES

# Create the build destination
RUN mkdir build cache
COPY $BUID_PATH build/

# Compile the application source code
RUN ["buildpack/bin/compile", "/build/", "/cache/"]

# Expose nginx port
ENV PORT 80
EXPOSE $PORT

# Start up application
WORKDIR /build
ENTRYPOINT ["python", "start.py"]
