# rhel-image-mode-lab

This repository is designed to organize the files and directory structure required at build time for validating RHEL Image Mode in different scenarios.

The root `Containerfile` defines the common base RHEL image, while each scenario under `scenarios/` represents a dedicated lab for testing a specific use case such as MVP deployment, update and rollback, transient debugging, agent integration, and VMware image generation.
