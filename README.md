# rhel-image-mode-lab

A hands-on lab collection for exploring RHEL Image Mode across different use cases. Each scenario under `scenarios/` is a self-contained lab with its own instructions.

## Repository Structure

```text
.
├── scripts/                     # Shared build helper scripts
└── scenarios/                   # Each subdirectory is a self-contained lab
```

## Prerequisites

- A subscribed RHEL system as the build host.
- `podman` installed.
- Access to `registry.redhat.io`.
- Image builds require **rootful Podman** (`sudo podman`) to access subscription data.
