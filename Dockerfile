# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
#
# Author: Mendix Digital Ecosystems, digitalecosystems@mendix.com
# Version: 1.4
FROM mendix/rootfs
LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Build-time variables
ARG BUILD_PATH=project

# Checkout CF Build-pack here
RUN mkdir -p buildpack/.local && \
   (wget -qO- https://github.com/mendix/cf-mendix-buildpack/archive/v1.9.2.tar.gz \
   | tar xvz -C buildpack --strip-components 1)

# Copy python scripts which execute the buildpack (exporting the VCAP variables)
COPY scripts/compilation /buildpack

# Add the buildpack modules
ENV PYTHONPATH "/buildpack/lib/"

# Create the build destination
RUN mkdir build cache
COPY $BUILD_PATH build

# Compile the application source code and remove temp files
WORKDIR /buildpack
RUN "/buildpack/compilation" /build /cache && \
  rm -fr /cache /tmp/javasdk /build/.local/usr/lib/jvm/jdk-* /usr/share/doc/* /tmp/opt/mono-*

# Expose nginx port
ENV PORT 80
EXPOSE $PORT

RUN mkdir -p "/.java/.userPrefs/com/mendix/core"
RUN mkdir -p "/root/.java/.userPrefs/com/mendix/core"
RUN ln -s "/.java/.userPrefs/com/mendix/core/prefs.xml" "/root/.java/.userPrefs/com/mendix/core/prefs.xml"

# Start up application
COPY scripts/ /build
WORKDIR /build
RUN chmod u+x startup
ENTRYPOINT ["/build/startup","/buildpack/start.py"]
