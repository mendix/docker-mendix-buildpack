# Prepare ubi-minimal image with base packages
FROM registry.access.redhat.com/ubi8/ubi as builder

ARG USER_UID=1001

# Mount ubi-micro rootfs
COPY --from=registry.access.redhat.com/ubi8/ubi-micro / /mnt/rootfs

# Install tools required to detect Mendix version
RUN dnf install \
    --installroot /mnt/rootfs --setopt install_weak_deps=false --nodocs -y \
    sqlite &&\
    dnf clean all --installroot /mnt/rootfs &&\
    rm -rf /mnt/rootfs/var/cache/* /mnt/rootfs/var/log/dnf* /mnt/rootfs/var/log/yum.*

COPY mx-version-detector.sh /usr/local/bin/
RUN chmod uga=rx /usr/local/bin/mx-version-detector.sh

# Create working directory
RUN mkdir -p /mnt/rootfs/workdir/project &&\
    chown -R $USER_UID:0 /mnt/rootfs/workdir

# Create version detector image
FROM registry.access.redhat.com/ubi8/ubi-micro

ARG USER_UID=1001

# Copy base OS dependencies
COPY --from=builder /mnt/rootfs/ /

COPY --from=builder /usr/local/bin/mx-version-detector.sh /usr/local/bin/

USER $USER_UID

CMD ["/usr/local/bin/mx-version-detector.sh"]
