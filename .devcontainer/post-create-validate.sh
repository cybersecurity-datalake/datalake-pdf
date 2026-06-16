#!/bin/bash

set -euo pipefail

LOGFILE=/tmp/devcontainer-post-create.log
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

exec > >(tee "$LOGFILE") 2>&1

setup_host_gpg() {
  local host_gnupg_dir="$HOME/.host-gnupg"
  local container_gnupg_dir="$HOME/.gnupg"

  mkdir -p "$container_gnupg_dir"
  chmod 700 "$container_gnupg_dir"

  if [ ! -d "$host_gnupg_dir" ]; then
    echo "[gpg] Host GPG directory not mounted; skipping GPG setup"
    return
  fi

  for file in pubring.kbx pubring.kbx~ trustdb.gpg gpg.conf; do
    if [ -f "$host_gnupg_dir/$file" ]; then
      cp -f "$host_gnupg_dir/$file" "$container_gnupg_dir/$file"
    fi
  done

  if [ -d "$host_gnupg_dir/openpgp-revocs.d" ]; then
    rm -rf "$container_gnupg_dir/openpgp-revocs.d"
    cp -a "$host_gnupg_dir/openpgp-revocs.d" "$container_gnupg_dir/openpgp-revocs.d"
  fi

  if [ -S "$container_gnupg_dir/S.gpg-agent" ]; then
    gpg-connect-agent updatestartuptty /bye >/dev/null 2>&1 || true
    echo "[gpg] Host agent socket forwarded to $(gpgconf --list-dir agent-socket)"
  else
    echo "[gpg] Host agent socket not mounted; commit signing will stay disabled"
  fi
}

setup_git_identity() {
  local host_git_user_name="${HOST_GIT_USER_NAME:-}"
  local host_git_user_email="${HOST_GIT_USER_EMAIL:-}"

  if [ -z "$host_git_user_name" ] || [ -z "$host_git_user_email" ]; then
    echo "[git] Host Git identity not provided; leaving container git user unset"
    return
  fi

  git config --global --replace-all user.name "$host_git_user_name"
  git config --global --replace-all user.email "$host_git_user_email"

  if [ "$(git config --global --get user.name || true)" != "$host_git_user_name" ]; then
    echo "[git] Failed to apply git user.name from the host"
    exit 1
  fi

  if [ "$(git config --global --get user.email || true)" != "$host_git_user_email" ]; then
    echo "[git] Failed to apply git user.email from the host"
    exit 1
  fi

  echo "[git] Configured git user.name=$host_git_user_name"
  echo "[git] Configured git user.email=$host_git_user_email"
}

setup_git_workspace_safety() {
  if git config --global --get-all safe.directory | grep -Fxq "$WORKSPACE_DIR"; then
    echo "[git] Workspace already marked as safe: $WORKSPACE_DIR"
    return
  fi

  git config --global --add safe.directory "$WORKSPACE_DIR"
  echo "[git] Added safe.directory=$WORKSPACE_DIR"
}

setup_host_ssh() {
  local host_ssh_dir="$HOME/.host-ssh"
  local container_ssh_dir="$HOME/.ssh"

  mkdir -p "$container_ssh_dir"
  chmod 700 "$container_ssh_dir"

  if [ -f "$host_ssh_dir/config" ]; then
    cp -f "$host_ssh_dir/config" "$container_ssh_dir/config"
    chmod 600 "$container_ssh_dir/config"
    echo "[ssh] Copied host SSH config"
  fi

  if [ -f "$host_ssh_dir/known_hosts" ]; then
    cp -f "$host_ssh_dir/known_hosts" "$container_ssh_dir/known_hosts"
    chmod 600 "$container_ssh_dir/known_hosts"
    echo "[ssh] Copied host known_hosts"
  fi

  if [ -S "${SSH_AUTH_SOCK:-}" ]; then
    echo "[ssh] Host SSH agent forwarded at ${SSH_AUTH_SOCK}"
  elif [ -n "${SSH_AUTH_SOCK:-}" ]; then
    echo "[ssh] SSH_AUTH_SOCK is set but no socket is available at ${SSH_AUTH_SOCK}"
    exit 1
  else
    echo "[ssh] Host SSH agent not mounted; SSH remotes may prompt for credentials"
  fi
}

seed_known_hosts_for_git_remotes() {
  local known_hosts_file="$HOME/.ssh/known_hosts"
  local remote_urls=""

  if ! git -C "$WORKSPACE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "[ssh] Workspace is not a Git work tree; skipping known_hosts seeding"
    return
  fi

  remote_urls="$(git -C "$WORKSPACE_DIR" remote get-url --all origin 2>/dev/null || true)"
  if [ -z "$remote_urls" ]; then
    echo "[ssh] No Git remotes found for known_hosts seeding"
    return
  fi

  touch "$known_hosts_file"
  chmod 600 "$known_hosts_file"

  while IFS= read -r remote_url; do
    local host=""

    case "$remote_url" in
      git@*:* )
        host="${remote_url#git@}"
        host="${host%%:*}"
        ;;
      ssh://* )
        host="${remote_url#ssh://}"
        host="${host#*@}"
        host="${host%%[:/]*}"
        ;;
    esac

    if [ -z "$host" ]; then
      continue
    fi

    if ssh-keygen -F "$host" -f "$known_hosts_file" >/dev/null 2>&1; then
      echo "[ssh] known_hosts already contains $host"
      continue
    fi

    ssh-keyscan -H "$host" >> "$known_hosts_file" 2>/dev/null
    echo "[ssh] Added $host to known_hosts"
  done <<< "$remote_urls"
}

echo "[$(date -Iseconds)] Starting devcontainer post-create validation"

echo
echo "[gpg-setup]"
setup_host_gpg

echo
echo "[git-setup]"
setup_git_identity
setup_git_workspace_safety

echo
echo "[ssh-setup]"
setup_host_ssh
seed_known_hosts_for_git_remotes

echo
echo "[tools]"
gpg --version | head -n 1
latexmk -v | head -n 1
chktex --version | head -n 1
latexindent --version | head -n 1
awk -W version | head -n 1
ping -V | head -n 1
ssh -V

echo
echo "[dns]"
getent hosts github.com

echo
echo "[https]"
curl -I --max-time 10 https://github.com | sed -n '1,5p'

echo
echo "[codex-installer-checksum-parser]"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT

checksum_asset="codex-package_SHA256SUMS"
package_asset="codex-package-x86_64-unknown-linux-musl.tar.gz"
curl -fsSLo "$tmpdir/$checksum_asset" \
  "https://github.com/openai/codex/releases/latest/download/$checksum_asset"

awk -v asset="$package_asset" '
  $2 == asset && $1 ~ /^[0-9a-fA-F]{64}$/ {
    print tolower($1)
    found = 1
    exit
  }
  END {
    if (!found) {
      exit 1
    }
  }
' "$tmpdir/$checksum_asset" >/dev/null

echo
echo "[$(date -Iseconds)] Devcontainer post-create validation completed successfully"
