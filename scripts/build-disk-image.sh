#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

IMAGE_NAME="${IMAGE_NAME:-localhost/rhel-image-mode-lab-base}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
SOURCE_IMAGE="${SOURCE_IMAGE:-${IMAGE_NAME}:${IMAGE_TAG}}"

OUTPUT_DIR="${OUTPUT_DIR:-./output}"
IMAGE_TYPE="${IMAGE_TYPE:-vmdk}"
BOOTC_BUILDER_IMAGE="${BOOTC_BUILDER_IMAGE:-registry.redhat.io/rhel9/bootc-image-builder:latest}"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [OPTIONS]

Build a bootable disk image from a locally available bootc image.

Options:
  -s, --source-image IMAGE    Source bootc image to convert
                              Default: ${SOURCE_IMAGE}
  -o, --output-dir PATH       Output directory for generated artifacts
                              Default: ${OUTPUT_DIR}
  -t, --type TYPE             Output image type: qcow2 | vmdk
                              Default: ${IMAGE_TYPE}
  -b, --builder-image IMAGE   bootc-image-builder container image
                              Default: ${BOOTC_BUILDER_IMAGE}
  -h, --help                  Show this help message

Environment variables:
  IMAGE_NAME                  Base image name
  IMAGE_TAG                   Base image tag
  SOURCE_IMAGE                Full source image reference
  OUTPUT_DIR                  Output directory
  IMAGE_TYPE                  Output image type (qcow2 or vmdk)
  BOOTC_BUILDER_IMAGE         bootc-image-builder image reference

Examples:
  $(basename "$0")
  $(basename "$0") --type qcow2
  $(basename "$0") --type vmdk
  $(basename "$0") --source-image localhost/rhel-image-mode-lab-base:latest --type qcow2
  $(basename "$0") --output-dir ./artifacts --type vmdk

Notes:
  - The source image must already exist locally.
  - You must be able to pull from registry.redhat.io.
  - This script uses a privileged podman container.
  - qcow2 is typically used for KVM/libvirt.
  - vmdk is typically used for VMware environments.

EOF
}

check_source_image() {
  if ! podman image exists "$SOURCE_IMAGE"; then
    err "Source image not found locally: $SOURCE_IMAGE"
    err "Please build it first, for example:"
    err "  ./scripts/build-base-image.sh"
    exit 1
  fi
}

check_image_type() {
  case "$IMAGE_TYPE" in
    qcow2|vmdk)
      ;;
    *)
      err "Unsupported image type: $IMAGE_TYPE"
      err "Supported types: qcow2, vmdk"
      exit 1
      ;;
  esac
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -s|--source-image)
        SOURCE_IMAGE="$2"
        shift 2
        ;;
      -o|--output-dir)
        OUTPUT_DIR="$2"
        shift 2
        ;;
      -t|--type)
        IMAGE_TYPE="$2"
        shift 2
        ;;
      -b|--builder-image)
        BOOTC_BUILDER_IMAGE="$2"
        shift 2
        ;;
      -h|--help)
        usage
        exit 0
        ;;
      *)
        err "Unknown option: $1"
        echo
        usage
        exit 1
        ;;
    esac
  done
}

main() {
  parse_args "$@"

  check_cmd podman
  check_image_type
  ensure_dir "$OUTPUT_DIR"
  check_source_image
  check_registry_login registry.redhat.io

  log "Source image: $SOURCE_IMAGE"
  log "Bootc builder image: $BOOTC_BUILDER_IMAGE"
  log "Output directory: $OUTPUT_DIR"
  log "Requested output type: $IMAGE_TYPE"

  podman run \
    --rm \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v "$(realpath "$OUTPUT_DIR"):/output" \
    "$BOOTC_BUILDER_IMAGE" \
    --type "$IMAGE_TYPE" \
    "$SOURCE_IMAGE"

  log "${IMAGE_TYPE} build completed."

  if [[ -d "${OUTPUT_DIR}/${IMAGE_TYPE}" ]]; then
    log "Artifacts generated under: ${OUTPUT_DIR}/${IMAGE_TYPE}"
    find "${OUTPUT_DIR}/${IMAGE_TYPE}" -maxdepth 2 -type f | sed 's/^/[INFO] /'
  else
    warn "Expected output directory not found: ${OUTPUT_DIR}/${IMAGE_TYPE}"
    warn "Please inspect the build logs above."
  fi
}

main "$@"
