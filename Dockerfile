# Dockerfile to create a Mendix Docker image based on either the source code or
# Mendix Deployment Archive (aka mda file)
#
# Author: Mendix Digital Ecosystems, digitalecosystems@mendix.com
# Version: 2.0.0
FROM mendix/rootfs
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
# Copy project model/sources
COPY $BUILD_PATH build

# Add the buildpack modules
ENV PYTHONPATH "/buildpack/lib/"

# Each comment corresponds to the script line:
# 1. Call compilation script
# 2. Remove temporary folders
# 3. Create mendix user with home directory at /root
# 4. Change ownership of /build /buildpack /.java /root to mendix
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
