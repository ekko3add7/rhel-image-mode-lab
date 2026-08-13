# 00-base-image

## Overview

This scenario builds the common base RHEL bootc image used by all other scenarios. It defines the standard system packages, timezone, NTP, journald settings, and container registry configuration.

## Directory Structure

```text
scenarios/00-base-image
├── Containerfile
├── config.toml
├── README.md
└── files
    ├── 099-ekko-registry.conf
    └── motd
```

## Workflow

### Step 1 - Build the base image

```bash
./scripts/build-base-image.sh
```

### Step 2 - Build a bootable disk image

Build QCOW2 for KVM:
```bash
./scripts/build-disk-image.sh --type qcow2
```

Build VMDK for VMware:
```bash
./scripts/build-disk-image.sh --type vmdk
```

### Step 3 - Push the base image to a registry

```bash
podman push localhost/rhel-image-mode-lab-base:latest registry.example.com/rhel-image-mode-lab-base:latest
```
