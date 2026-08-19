#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Script:      uninstall.sh
# Description: Remove general-skills from the local machine. Removes copied
#              skill/agent directories using the manifest written by
#              install.sh. Idempotent — safe to re-run.
# Usage:       uninstall.sh [options]
# -----------------------------------------------------------------------------

VERBOSE=false
DRY_RUN=false

MANIFEST_DIR="${HOME}/.general-skills/manifest"

info()    { echo "[INFO]  $*"; }
verbose() { [[ "$VERBOSE" == true ]] && echo "[DEBUG] $*" || true; }

usage() {
  echo "Usage: $(basename "$0") [options]"
  echo ""
  echo "Options:"
  echo "  -v, --verbose    Enable verbose output"
  echo "  -n, --dry-run    Show what would be removed without removing anything"
  echo "  -h, --help       Show this help message and exit"
  exit 1
}

remove_path() {
  local target="$1"
  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] Would remove: $target"
    return
  fi

  if [[ -d "$target" ]]; then
    rm -rf "$target"
    info "Removed directory: $target"
  elif [[ -f "$target" ]]; then
    rm "$target"
    info "Removed file: $target"
  else
    verbose "Already gone, skipping: $target"
  fi
}

remove_manifest_entries() {
  local category="$1"
  local manifest_file="${MANIFEST_DIR}/${category}"

  [[ -f "$manifest_file" ]] || { verbose "No manifest for category: $category"; return; }

  info "Removing ${category}..."
  while IFS= read -r target; do
    [[ -z "$target" ]] && continue
    remove_path "$target"
  done < "$manifest_file"

  if [[ "$DRY_RUN" == false ]]; then
    rm "$manifest_file"
  fi
}

remove_manifest_dir() {
  [[ -d "$MANIFEST_DIR" ]] || return
  if [[ "$DRY_RUN" == true ]]; then
    info "[dry-run] Would remove manifest directory: $MANIFEST_DIR"
    return
  fi

  if [[ -z "$(ls -A "$MANIFEST_DIR")" ]]; then
    rmdir "$MANIFEST_DIR"
    local parent
    parent="$(dirname "$MANIFEST_DIR")"
    if [[ -d "$parent" ]] && [[ -z "$(ls -A "$parent")" ]]; then
      rmdir "$parent"
    fi
  else
    echo "[WARN]  Manifest directory is not empty after uninstall — leaving in place: $MANIFEST_DIR" >&2
  fi
}

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--verbose) VERBOSE=true ;;
      -n|--dry-run) DRY_RUN=true ;;
      -h|--help)    usage ;;
      --)           shift; break ;;
      -*) echo "[ERROR] Unknown flag: $1. Run with -h for usage." >&2; exit 1 ;;
      *)  break ;;
    esac
    shift
  done

  [[ "$DRY_RUN" == true ]] && info "Dry-run mode — no changes will be made."

  info "Starting general-skills uninstall..."
  verbose "Manifest: $MANIFEST_DIR"

  remove_manifest_entries "skills"
  remove_manifest_entries "agents"
  remove_manifest_dir

  info "general-skills uninstall complete."
}

main "$@"
