ARG IMAGE_MXBUILD
ARG IMAGE_RUNTIME
ARG MX_VERSION
ARG MODEL_VERSION=unknown

FROM ${IMAGE_MXBUILD}:${MX_VERSION} as builder

ARG USER_UID=1001

# Build the project
COPY --chown=$USER_UID:0 . /workdir/project
RUN mxbuild.sh

FROM ${IMAGE_RUNTIME}:${MX_VERSION}

ARG USER_UID=1001

# Copy the build artifacts
COPY --from=builder /workdir/app /opt/mendix/app

# App container configuration
USER ${USER_UID}

CMD ["/opt/mendix/init/mxruntime.sh"]
