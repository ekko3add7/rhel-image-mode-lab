# 01-mvp

## Overview

This scenario demonstrates a simple MVP workflow for **RHEL Image Mode**:

1. Temporarily install a package on a running Image Mode instance for testing
2. After validation, add the package into the image by updating the root `Containerfile`
3. Build a new bootable image
4. Upgrade the system to the new image
5. Verify lifecycle operations:
   - `bootc upgrade`
   - rollback
   - image switching

This is a practical example of moving from **runtime testing** to **image-based delivery**.

## Mutable areas in a running RHEL Image Mode instance

Under the RHEL Image Mode architecture, although the root filesystem is immutable by default, modifications on a running instance still fall into two categories:

- **Persistent changes**: retained after reboot
- **Transient changes**: lost after reboot

This distinction is important when validating changes on a live system versus deciding what should ultimately be baked into the image.

### Persistent changes

The following changes can persist across reboots.

#### 1. `/etc` - system configuration

By default, `/etc` is persistent and mutable. Changes made to configuration files on the running system are retained, and the system performs a **3-way merge** during upgrades to preserve local modifications whenever possible.

#### 2. `/var` - system data, logs, and user data

he `/var` directory is intended for data that changes over time, such as logs, databases, caches, and user home data under `/var/home`.
Changes under `/var` are persistent by default. In addition, data in `/var` is generally **not rolled back** even if the operating system deployment is rolled back.

#### 3. Kernel arguments

Machine-local kernel argument changes are allowed and can persist. These can be managed through commands such as `rpm-ostree kargs`, or by providing configuration under `/usr/lib/bootc/kargs.d` during image build time.

### Transient changes

The following changes are temporary and do not survive a reboot.

#### 1. `/usr` overlay for temporary package installation

Although `/usr` is read-only by default, you can create a writable overlay for temporary testing. This is commonly used to install debugging or troubleshooting tools on a running instance.

For example, `bootc-usr-overlay` can be used to create a writable overlay on top of `/usr`. Any packages installed this way are **temporary** and will be lost after reboot.


#### 2. Root filesystem `/` and dynamic top-level mount points

If `transient-ro=true` is enabled at image build time, privileged processes such as `root` or `systemd` services can remount the root filesystem as writable within a private mount namespace.

This allows creation of dynamic top-level mount points such as `/afs` or platform-specific directories like `/users`.

These changes remain available only for the current boot session.

#### 3. `/run` - in-memory transient runtime configuration

The `/run` directory is designed for transient runtime state. It is cleared on reboot and should be used when you want to apply temporary changes without writing them to disk.

## Scenario Flow

### Step 1 - Temporarily install a package on a running instance

In some cases, you may want to verify whether a package is really needed before rebuilding the image.
You can temporarily install a package on the running host for testing purposes.

```bash
bootc usr-overlay
dnf install -y nginx
```

### Step 2 - Add the package into the Containerfile then build and push
```bash
RUN dnf install -y nginx && \
    dnf clean all
```

### Step 3 - Upgrade and Lifecycle Verification
After publishing the new image, the running Image Mode system can move to the updated version.

#### Step 3.1 bootc upgrade
To manually fetch updates from a registry and boot the system into the new updates, use bootc upgrade. This command fetches the transactional in-place updates from the installed operating system to the container image registry. 
```bash
bootc upgrade
systemctl reboot 
# (only for RHEL 10), bootc update --soft-reboot=required --apply 
bootc status
```

#### Step 3.2 Rollback
You can roll back to a previous boot entry to revert changes in the system by using the bootc rollback command.
```bash
bootc rollback
systemctl reboot
bootc status
```

#### Step 3.3 Switching
You can change the container image reference used for upgrades by using the bootc switch command. For example, you can switch from the test to the production tag.
```bash
bootc switch registry.example.com/rhel-image-mode-lab:prod
```