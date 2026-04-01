# 02-developer-base-image

## Overview
This lab demonstrates a standardized enterprise workflow based on RHEL Image Mode.

In this scenario, a Platform Admin defines a standard base image built on RHEL Image Mode and delivers it to the development team. The development team then extends that image by integrating an Nginx web service and deploying an internal web portal page.

The purpose of this scenario is to show how RHEL Image Mode can support both platform standardization and application delivery in a single image-based workflow.

## Directory Structure

```text
scenarios/02-developer-base-image
├── Containerfile
├── README.md
└── files
    └── index.html
```

## Workflow

### Step 1 - Build the scenario image based on root image
```bash
./scripts/build-base-image.sh \
  --file ./scenarios/02-developer-base-image/Containerfile \
  --context ./scenarios/02-developer-base-image \
  -t 0.1 \
  -n registry.ekko.com:5000/rhel-image-mode-lab-base-nginx

podman push registry.ekko.com:5000/rhel-image-mode-lab-base-nginx:0.1
```

### Step 2 - Switching
```bash
bootc status
bootc switch registry.ekko.com:5000/rhel-image-mode-lab-base-nginx:0.1
bootc status
reboot
```

### Step 3 HTTP access
Confirm tht the web page can be accessed locally or remotely.
```bash
curl http://localhost
or
curl http://<vm-ip-address>
```
