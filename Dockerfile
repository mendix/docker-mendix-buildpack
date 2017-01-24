# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
#
# Author: Mendix Digital Ecosystems, digitalecosystems@mendix.com
# Version: 1.0

FROM cloudfoundry/cflinuxfs2
MAINTAINER Mendix Digital Ecosystems <digitalecosystems@mendix.com>

# Build-time variables
ARG BUILD_PATH

# Checkout CF Build-pack here
RUN mkdir -p buildpack/.local && \
  (wget -qO- https://github.com/mendix/cf-mendix-buildpack/archive/master.tar.gz \
  | tar xvz -C buildpack --strip-components 1)

# Copy python scripts which execute the buildpack (exporting the VCAP variables)
COPY scripts /buildpack

# Add the buildpack modules
ENV PYTHONPATH "/buildpack/lib/"

# Create the build destination
RUN mkdir build cache
COPY $BUILD_PATH build

# Compile the application source code
WORKDIR /buildpack
RUN "/buildpack/compilation" /build /cache

# Expose nginx port
ENV PORT 80
EXPOSE $PORT

# Start up application
COPY scripts /build
WORKDIR /build
RUN chmod u+x startup
ENTRYPOINT ["/build/startup","/build/start.py"]
