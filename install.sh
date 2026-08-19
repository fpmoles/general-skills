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
#              Optionally enables this repo's tracked git hooks (.github/hooks/)
#              via core.hooksPath, which re-run this script after every pull/push.
# Usage:       install.sh [options]
# -----------------------------------------------------------------------------

VERBOSE=false

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MANIFEST_DIR="${HOME}/.general-skills/manifest"

SKILL_DIRS=("${HOME}/.claude/skills" "${HOME}/.codex/skills" "${HOME}/.copilot/skills" "${HOME}/.agents/skills")
AGENT_DIRS=("${HOME}/.claude/agents" "${HOME}/.codex/agents" "${HOME}/.copilot/agents")

GIT_HOOKS_DIR=".github/hooks"
GIT_HOOK_NAMES=("pre-commit" "post-merge" "pre-push")

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
# Git hooks
# -----------------------------------------------------------------------------
# Hook scripts themselves live tracked in $GIT_HOOKS_DIR (this repo, every
# clone) — this function's only job is turning them on for this checkout via
# `core.hooksPath`, gated on explicit confirmation.

configure_git_hooks() {
  local current
  current="$(git -C "$REPO_DIR" config --get core.hooksPath || true)"

  if [[ "$current" == "$GIT_HOOKS_DIR" ]]; then
    verbose "Git hooks already enabled via core.hooksPath=$GIT_HOOKS_DIR."
    return
  fi

  if [[ -n "$current" ]]; then
    warn "core.hooksPath is already set to '$current' — leaving it alone. Run 'git config core.hooksPath $GIT_HOOKS_DIR' yourself to switch to general-skills' tracked hooks (${GIT_HOOK_NAMES[*]})."
    return
  fi

  if [[ ! -t 0 ]]; then
    warn "Skipping git hooks setup (non-interactive shell). Run 'git config core.hooksPath $GIT_HOOKS_DIR' manually, or re-run install.sh from an interactive terminal, to enable: ${GIT_HOOK_NAMES[*]}."
    return
  fi

  printf "Enable general-skills' git hooks (%s) via core.hooksPath? [y/N] " "${GIT_HOOK_NAMES[*]}"
  read -r response
  case "$response" in
    [yY][eE][sS]|[yY])
      git -C "$REPO_DIR" config core.hooksPath "$GIT_HOOKS_DIR"
      info "Enabled git hooks: ${GIT_HOOK_NAMES[*]} (core.hooksPath=$GIT_HOOKS_DIR)."
      ;;
    *)
      verbose "Skipping git hooks setup."
      ;;
  esac
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
  configure_git_hooks

  info "general-skills install complete."
}

main "$@"
