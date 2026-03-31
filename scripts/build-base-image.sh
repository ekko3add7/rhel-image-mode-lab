#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./common.sh
source "${SCRIPT_DIR}/common.sh"

IMAGE_NAME="${IMAGE_NAME:-localhost/rhel-image-mode-lab-base}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINERFILE="${CONTAINERFILE:-./Containerfile}"
BUILD_CONTEXT="${BUILD_CONTEXT:-.}"

usage() {
  cat <<EOF
Usage:
  $(basename "$0") [OPTIONS]

Build the root Containerfile as the common base image for this repository.

Options:
  -n, --image-name NAME       Target image name
                              Default: ${IMAGE_NAME}
  -t, --image-tag TAG         Target image tag
                              Default: ${IMAGE_TAG}
  -f, --file PATH             Path to Containerfile
                              Default: ${CONTAINERFILE}
  -c, --context PATH          Build context directory
                              Default: ${BUILD_CONTEXT}
  -h, --help                  Show this help message

Environment variables:
  IMAGE_NAME                  Override image name
  IMAGE_TAG                   Override image tag
  CONTAINERFILE               Override Containerfile path
  BUILD_CONTEXT               Override build context path

Examples:
  $(basename "$0")
  $(basename "$0") --image-tag 9.6
  $(basename "$0") --image-name localhost/rhel-image-mode-lab-base --image-tag latest
  $(basename "$0") --file ./Containerfile --context .

EOF
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--image-name)
        IMAGE_NAME="$2"
        shift 2
        ;;
      -t|--image-tag)
        IMAGE_TAG="$2"
        shift 2
        ;;
      -f|--file)
        CONTAINERFILE="$2"
        shift 2
        ;;
      -c|--context)
        BUILD_CONTEXT="$2"
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
  require_file "$CONTAINERFILE"

  log "Building base image from: $CONTAINERFILE"
  log "Build context: $BUILD_CONTEXT"
  log "Target image: ${IMAGE_NAME}:${IMAGE_TAG}"

  # podman build -f ./Containerfile -t localhost/rhel-image-mode-lab-base:latest .
  podman build \
    -f "$CONTAINERFILE" \
    -t "${IMAGE_NAME}:${IMAGE_TAG}" \
    "$BUILD_CONTEXT"

  log "Build completed successfully."
  log "Built image: ${IMAGE_NAME}:${IMAGE_TAG}"
}

main "$@"
