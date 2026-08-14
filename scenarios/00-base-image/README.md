# 00-base-image

## Overview

This scenario builds a **Standard Operating Environment (SOE)** bootc image using RHEL Image Mode.

An SOE image defines the organization's baseline — required packages, security hardening, compliance settings, time synchronization, and logging policies. Once built and pushed to a container registry, this image serves as the **golden image** that all other scenarios and teams can extend.

See `Containerfile` and `files/` for the specific configuration applied to the SOE image.

## Build the SOE image

```bash
cd scenarios/00-base-image

podman build -f Containerfile -t localhost/rhel-image-mode-lab-base:latest .
```

Alternatively, use the helper script `./scripts/build-base-image.sh`.

## Push to a registry

```bash
podman push localhost/rhel-image-mode-lab-base:latest <registry>/rhel-image-mode-lab-base:<tag>
```

## Convert to a bootable disk image (optional)

Convert the SOE image into a VM disk image using `bootc-image-builder`.

### config.toml

`config.toml` is the configuration file consumed by `bootc-image-builder` to customize the disk image. It defines:

- **User accounts** — initial user, password, SSH key, and group membership.
- **Disk partitioning** — the partition layout applied when generating the disk image.

Current partition layout:

| Partition | Type | Filesystem | Size | Mount Point |
|---|---|---|---|---|
| EFI | plain | vfat | 200 MiB | `/boot/efi` |
| boot | plain | xfs | 1 GiB | `/boot` |
| data | plain | ext4 | 1 GiB | `/data` |
| rootlv | LVM (`rhel`) | xfs | 5 GiB | `/` |
| var_log | LVM (`rhel`) | xfs | 5 GiB | `/var/log` |
| var_log_audit | LVM (`rhel`) | xfs | 1 GiB | `/var/log/audit` |
| swaplv | LVM (`rhel`) | swap | 1 GiB | — |

Build QCOW2 for KVM / libvirt:
```bash
podman run --rm --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v ./scenarios/00-base-image/config.toml:/config.toml:ro \
  -v ./output:/output \
  registry.redhat.io/rhel9/bootc-image-builder:latest \
  --type qcow2 localhost/rhel-image-mode-lab-base:latest
```

Build VMDK for VMware:
```bash
podman run --rm --privileged --pull=newer \
  --security-opt label=type:unconfined_t \
  -v /var/lib/containers/storage:/var/lib/containers/storage \
  -v ./scenarios/00-base-image/config.toml:/config.toml:ro \
  -v ./output:/output \
  registry.redhat.io/rhel9/bootc-image-builder:latest \
  --type vmdk localhost/rhel-image-mode-lab-base:latest
```

Alternatively, use the helper script `./scripts/build-disk-image.sh --type qcow2|vmdk`.
