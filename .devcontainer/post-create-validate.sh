#!/bin/bash

set -euo pipefail

LOGFILE=/tmp/devcontainer-post-create.log

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

  git config --global user.name "$host_git_user_name"
  git config --global user.email "$host_git_user_email"

  echo "[git] Configured git user.name=$host_git_user_name"
  echo "[git] Configured git user.email=$host_git_user_email"
}

echo "[$(date -Iseconds)] Starting devcontainer post-create validation"

echo
echo "[gpg-setup]"
setup_host_gpg

echo
echo "[git-setup]"
setup_git_identity

echo
echo "[tools]"
gpg --version | head -n 1
latexmk -v | head -n 1
chktex --version | head -n 1
latexindent --version | head -n 1
awk -W version | head -n 1
ping -V | head -n 1

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
