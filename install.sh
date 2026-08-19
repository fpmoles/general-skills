#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Script:      install.sh
# Description: Install general-skills onto the local machine. Copies each
#              skill/agent folder to every AI tool's expected skills/agents
#              directory (Claude, Codex, Copilot, and the generic ~/.agents
#              convention). Idempotent — safe to re-run. Manages a manifest at
#              ~/.general-skills/manifest/ to track only what this script
#              controls, so re-running cleans up anything removed from the
#              repo and a stray file in a tool's skills dir is left alone.
# Usage:       install.sh [options]
# -----------------------------------------------------------------------------

VERBOSE=false

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${HOME}/.general-skills/manifest"

SKILL_DIRS=("${HOME}/.claude/skills" "${HOME}/.codex/skills" "${HOME}/.copilot/skills" "${HOME}/.agents/skills")
AGENT_DIRS=("${HOME}/.claude/agents" "${HOME}/.codex/agents" "${HOME}/.copilot/agents")

info()    { echo "[INFO]  $*"; }
warn()    { echo "[WARN]  $*" >&2; }
verbose() { [[ "$VERBOSE" == true ]] && echo "[DEBUG] $*" || true; }

usage() {
  echo "Usage: $(basename "$0") [options]"
  echo ""
  echo "Options:"
  echo "  -v, --verbose    Enable verbose output"
  echo "  -h, --help       Show this help message and exit"
  exit 1
}

# -----------------------------------------------------------------------------
# Manifest
# -----------------------------------------------------------------------------

read_manifest() {
  local category="$1"
  local file="${MANIFEST_DIR}/${category}"
  if [[ -f "$file" ]]; then
    cat "$file"
  fi
}

write_manifest() {
  local category="$1"
  local contents="$2"
  mkdir -p "$MANIFEST_DIR"
  if [[ -n "$contents" ]]; then
    echo "$contents" > "${MANIFEST_DIR}/${category}"
  else
    rm -f "${MANIFEST_DIR}/${category}"
  fi
  verbose "Manifest updated: $category"
}

# -----------------------------------------------------------------------------
# Copy management
# -----------------------------------------------------------------------------

cleanup_copies() {
  local category="$1"
  local existing
  existing="$(read_manifest "$category")"
  [[ -z "$existing" ]] && return

  echo "$existing" | while read -r target; do
    [[ -z "$target" ]] && continue
    if [[ -d "$target" ]]; then
      rm -rf "$target"
      verbose "Removed managed directory: $target"
    elif [[ -f "$target" ]]; then
      rm "$target"
      verbose "Removed managed copy: $target"
    fi
  done
}

copy_dir() {
  local source="$1"
  local target="$2"
  mkdir -p "$target"
  cp -r "${source}/." "$target"
  info "Copied: $target"
}

# -----------------------------------------------------------------------------
# Install steps
# -----------------------------------------------------------------------------

install_skills() {
  info "Installing skills..."
  cleanup_copies "skills"

  local new_manifest=""
  local skill_dir name dest_dir target

  for skill_dir in "${REPO_DIR}/skills/"/*/; do
    [[ -d "$skill_dir" ]] || continue
    name="$(basename "$skill_dir")"

    for dest_dir in "${SKILL_DIRS[@]}"; do
      target="${dest_dir}/${name}"
      copy_dir "$skill_dir" "$target"
      new_manifest="${new_manifest}${target}
"
    done
  done

  write_manifest "skills" "$new_manifest"
  info "Skills install complete."
}

install_agents() {
  info "Installing agents..."
  cleanup_copies "agents"

  local new_manifest=""
  local agent_dir name dest_dir target

  for agent_dir in "${REPO_DIR}/agents/"/*/; do
    [[ -d "$agent_dir" ]] || continue
    name="$(basename "$agent_dir")"

    for dest_dir in "${AGENT_DIRS[@]}"; do
      target="${dest_dir}/${name}"
      copy_dir "$agent_dir" "$target"
      new_manifest="${new_manifest}${target}
"
    done
  done

  write_manifest "agents" "$new_manifest"
  info "Agents install complete."
}

# -----------------------------------------------------------------------------
# Main
# -----------------------------------------------------------------------------

main() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -v|--verbose) VERBOSE=true ;;
      -h|--help)    usage ;;
      --)           shift; break ;;
      -*) echo "[ERROR] Unknown flag: $1. Run with -h for usage." >&2; exit 1 ;;
      *)  break ;;
    esac
    shift
  done

  info "Starting general-skills install..."
  verbose "Repo: $REPO_DIR"
  verbose "Manifest: $MANIFEST_DIR"

  install_skills
  install_agents

  info "general-skills install complete."
}

main "$@"
