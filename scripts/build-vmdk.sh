#!/usr/bin/env bash
set -Eeuo pipefail

IMAGE_NAME="${IMAGE_NAME:-localhost/rhel-image-mode-lab-base}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
SOURCE_IMAGE="${SOURCE_IMAGE:-${IMAGE_NAME}:${IMAGE_TAG}}"

OUTPUT_DIR="${OUTPUT_DIR:-./output}"
BOOTC_BUILDER_IMAGE="${BOOTC_BUILDER_IMAGE:-registry.redhat.io/rhel9/bootc-image-builder:latest}"

log() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

err() {
  echo "[ERROR] $*" >&2
}

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [OPTIONS]

Build a VMDK disk image from a locally available bootc base image.

Options:
  -s, --source-image IMAGE    Source bootc image to convert
                              Default: ${SOURCE_IMAGE}
  -o, --output-dir PATH       Output directory for generated artifacts
                              Default: ${OUTPUT_DIR}
  -b, --builder-image IMAGE   bootc-image-builder container image
                              Default: ${BOOTC_BUILDER_IMAGE}
  -h, --help                  Show this help message

Environment variables:
  IMAGE_NAME                  Base image name
  IMAGE_TAG                   Base image tag
  SOURCE_IMAGE                Full source image reference
  OUTPUT_DIR                  Output directory
  BOOTC_BUILDER_IMAGE         bootc-image-builder image reference

Examples:
  $(basename "$0")
  $(basename "$0") --source-image localhost/rhel-image-mode-lab-base:latest
  $(basename "$0") --output-dir ./artifacts
  $(basename "$0") --builder-image registry.redhat.io/rhel9/bootc-image-builder:latest

Notes:
  - The source image must already exist locally.
  - You must be able to pull from registry.redhat.io.
  - This script uses a privileged podman container.

EOF
}

check_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Required command not found: $1"
    exit 1
  }
}

check_registry_login() {
  local registry="$1"
  if ! podman login --get-login "$registry" >/dev/null 2>&1; then
    warn "You are not logged in to $registry"
    warn "Please run: podman login $registry"
  fi
}

prepare_output_dir() {
  mkdir -p "$OUTPUT_DIR"
}

check_source_image() {
  if ! podman image exists "$SOURCE_IMAGE"; then
    err "Source image not found locally: $SOURCE_IMAGE"
    err "Please build it first, for example:"
    err "  ./scripts/build-base-image.sh"
    exit 1
  fi
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
  prepare_output_dir
  check_source_image
  check_registry_login registry.redhat.io

  log "Source image: $SOURCE_IMAGE"
  log "Bootc builder image: $BOOTC_BUILDER_IMAGE"
  log "Output directory: $OUTPUT_DIR"
  log "Requested output type: vmdk"

  podman run \
    --rm \
    --privileged \
    --pull=newer \
    --security-opt label=type:unconfined_t \
    -v /var/lib/containers/storage:/var/lib/containers/storage \
    -v "$(realpath "$OUTPUT_DIR"):/output" \
    "$BOOTC_BUILDER_IMAGE" \
    --type vmdk \
    "$SOURCE_IMAGE"

  log "VMDK build completed."

  if [[ -d "${OUTPUT_DIR}/vmdk" ]]; then
    log "Artifacts generated under: ${OUTPUT_DIR}/vmdk"
    find "${OUTPUT_DIR}/vmdk" -maxdepth 2 -type f | sed 's/^/[INFO] /'
  else
    warn "Expected output directory not found: ${OUTPUT_DIR}/vmdk"
    warn "Please inspect the build logs above."
  fi
}

main "$@"
