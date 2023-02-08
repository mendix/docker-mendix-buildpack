FROM registry.access.redhat.com/ubi8/ubi-minimal

ARG USER_UID=1001

RUN microdnf install sqlite --setopt install_weak_deps=0 --nodocs -y && \
    microdnf clean all && \
    rm -rf /var/cache/* /var/log/dnf* /var/log/yum.*

COPY mx-version-detector.sh /usr/local/bin/

USER $USER_UID
