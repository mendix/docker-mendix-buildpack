# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
#
# Author: Mendix Digital Ecosystems, digitalecosystems@mendix.com
# Version: 2.0.0
ARG ROOTFS_IMAGE=mendix/rootfs

FROM ${ROOTFS_IMAGE}

LABEL Author="Mendix Digital Ecosystems"
LABEL maintainer="digitalecosystems@mendix.com"

# Build-time variables
ARG BUILD_PATH=project
ARG DD_API_KEY
# CF buildpack version
ARG CF_BUILDPACK=master

# Each comment corresponds to the script line:
# 1. Create all directories needed by scripts
# 2. Create all directories needed by CF buildpack
# 3. Create symlink for java prefs used by CF buildpack
# 4. Download CF buildpack
RUN mkdir -p buildpack build cache \
   "/.java/.userPrefs/com/mendix/core" "/root/.java/.userPrefs/com/mendix/core" &&\
   ln -s "/.java/.userPrefs/com/mendix/core/prefs.xml" "/root/.java/.userPrefs/com/mendix/core/prefs.xml" &&\
   echo "CF Buildpack version ${CF_BUILDPACK}" &&\
   wget -qO- https://github.com/mendix/cf-mendix-buildpack/archive/${CF_BUILDPACK}.tar.gz | tar xvz -C buildpack --strip-components 1

# Copy python scripts which execute the buildpack (exporting the VCAP variables)
COPY scripts/compilation /buildpack

# Add the buildpack modules
ENV PYTHONPATH "/buildpack/lib/"

# Create the build destination
RUN mkdir build cache
COPY $BUILD_PATH build

# Compile the application source code and remove temp files
WORKDIR /buildpack
RUN chmod +x /buildpack/compilation
RUN "/buildpack/compilation" /build /cache && \
  rm -fr /cache /tmp/javasdk /tmp/opt

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
