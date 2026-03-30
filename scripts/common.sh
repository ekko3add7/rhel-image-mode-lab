#!/usr/bin/env bash

log() {
  echo "[INFO] $*"
}

warn() {
  echo "[WARN] $*" >&2
}

err() {
  echo "[ERROR] $*" >&2
}

check_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    err "Required command not found: $1"
    exit 1
  }
}

require_file() {
  [[ -f "$1" ]] || {
    err "File not found: $1"
    exit 1
  }
}

ensure_dir() {
  mkdir -p "$1"
}

check_registry_login() {
  local registry="$1"
  if ! podman login --get-login "$registry" >/dev/null 2>&1; then
    warn "You are not logged in to $registry"
    warn "Please run: podman login $registry"
  fi
}
