# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
#
# Author: Mendix Digital Ecosystems, digitalecosystems@mendix.com
# Version: 1.5
FROM mendix/rootfs
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Build-time variables
ARG BUILD_PATH=project
ARG DD_API_KEY

# Checkout CF Build-pack here
RUN mkdir -p buildpack/.local && \
   (wget -qO- https://github.com/mendix/cf-mendix-buildpack/archive/master.tar.gz \
   | tar xvz -C buildpack --strip-components 1)

# Copy python scripts which execute the buildpack (exporting the VCAP variables)
COPY scripts/compilation /buildpack 

# Add the buildpack modules
ENV PYTHONPATH "/buildpack/lib/"

# Create the build destination
RUN mkdir build cache
COPY $BUILD_PATH build

# Create directories required by buildpack
RUN mkdir -p "/.java/.userPrefs/com/mendix/core"
RUN mkdir -p "/root/.java/.userPrefs/com/mendix/core"
RUN ln -s "/.java/.userPrefs/com/mendix/core/prefs.xml" "/root/.java/.userPrefs/com/mendix/core/prefs.xml"

# Compile the application source code and remove temp files
WORKDIR /buildpack
RUN "/buildpack/compilation" /build /cache &&\
    rm -fr /cache /tmp/javasdk /tmp/opt &&\
    useradd -r -U -d /root mendix &&\
    chown -R mendix /buildpack /build /.java /root 

# Copy start scripts
COPY --chown=mendix:mendix scripts/startup /build
COPY --chown=mendix:mendix scripts/vcap_application.json /build
WORKDIR /build

USER mendix

# Expose nginx port
ENV PORT 8080
EXPOSE $PORT

ENTRYPOINT ["/build/startup","/buildpack/start.py"]
