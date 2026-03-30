# rhel-image-mode-lab

This repository is designed to organize the files and directory structure required at build time for validating RHEL Image Mode in different scenarios.

The root `Containerfile` defines the common base RHEL image, while each scenario under `scenarios/` represents a dedicated lab for testing a specific use case such as MVP deployment, update and rollback, transient debugging, agent integration, and VMware image generation.

## Repository Structure

```text
.
├── Containerfile
├── LICENSE
├── README.md
├── scripts
│   ├── common.sh
│   ├── build-base-image.sh
│   └── build-disk-image.sh
└── scenarios
    └── 01-mvp
```

## Prerequisites

Before building images, make sure the host system meets the following requirements:
- The host is a subscribed RHEL system.
- `podman` is installed.
- You can access `registry.redhat.io`.
- Image build must use **rootful Podman** (`sudo podman`), not rootless Podman (To get subscription data)


## Build the Base Image

Build the common base image from the root `Containerfile`:

```bash
./scripts/build-base-image.sh
```

Example with a custom tag:
```bash
./scripts/build-base-image.sh --image-tag 9.6
```

Show help:
```bash
./scripts/build-base-image.sh --help
```

## Build a Bootable Disk Image

After the base image is built, use the disk image build script to convert it into a bootable VM image.

Build QCOW2 for KVM:
```bash
./scripts/build-disk-image.sh --type qcow2
```

Build VMDK for VMware:
```bash
./scripts/build-disk-image.sh --type vmdk
```

Specify a custom source image:
```bash
./scripts/build-disk-image.sh \
  --source-image localhost/rhel-image-mode-lab-base:latest \
  --type qcow2
```

Specify a custom output directory:

```bash
./scripts/build-disk-image.sh \
  --type vmdk \
  --output-dir ./artifacts
```

Show help:
```bash
./scripts/build-disk-image.sh --help
```

## Next Steps

After building the base image, proceed to a scenario-specific lab under `scenarios/` such as `01-mvp` to validate end-to-end workflows.
