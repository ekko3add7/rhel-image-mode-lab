# Common base image used by all scenarios in this repository
FROM registry.redhat.io/rhel9/rhel-bootc:9.7

LABEL name="rhel-image-mode-lab-base"
LABEL maintainer="Ekko Chang <ekko.chang@redhat.com>"
LABEL summary="Base RHEL bootc image for image mode lab scenarios"
LABEL description="Common base image used by all scenarios in the rhel-image-mode-lab repository"

RUN dnf -y install \
            chrony sos sysstat tcpdump iproute net-tools bash-completion \
            pesign gdb kexec-tools rsync wget curl strace ipa-client \
            open-vm-tools qemu-guest-agent \
    && dnf clean all


# -----------------------------------------------------------------------------
# Basic system settings
# -----------------------------------------------------------------------------
# Banner
RUN printf '%s\n' \
    'RHEL Image Mode Lab Base Image' \
    'This system is built from the root Containerfile of rhel-image-mode-lab.' \
    > /etc/motd

# Timezone
RUN ln -sf /usr/share/zoneinfo/Asia/Taipei /etc/localtime && \
    echo 'Asia/Taipei' > /etc/timezone

# Chrony
RUN printf '%s\n' \
    'server 10.102.254.34 iburst' \
    'driftfile /var/lib/chrony/drift' \
    'makestep 1.0 3' \
    'rtcsync' \
    'keyfile /etc/chrony.keys' \
    'leapsectz right/UTC' \
    'logdir /var/log/chrony' \
    > /etc/chrony.conf && \
    mkdir -p /var/log/chrony

# Journald
RUN mkdir -p /etc/systemd/journald.conf.d && \
    printf '%s\n' \
      '[Journal]' \
      'Storage=persistent' \
      'Compress=yes' \
      > /etc/systemd/journald.conf.d/persistent.conf

# -----------------------------------------------------------------------------
# Services settings
# -----------------------------------------------------------------------------
RUN systemctl enable chronyd