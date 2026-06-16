#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
resources_file="$script_dir/.env.resources"
compose_env_file="$script_dir/.env"
compose_host_file="$script_dir/compose.host.yaml"

mem_limit="2G"
cpu_limit="1"
host_git_user_name="$(git config --global --get user.name 2>/dev/null || true)"
host_git_user_email="$(git config --global --get user.email 2>/dev/null || true)"

escape_compose_env() {
  local value="$1"
  value="${value//\\/\\\\}"
  value="${value//\"/\\\"}"
  printf '"%s"' "$value"
}

if [ -f "$resources_file" ]; then
  while IFS='=' read -r key value; do
    case "$key" in
      ""|\#*)
        continue
        ;;
      MEM_LIMIT)
        mem_limit="${value}"
        ;;
      CPU_LIMIT)
        cpu_limit="${value}"
        ;;
    esac
  done < "$resources_file"
fi

host_gnupg_dir="${HOME}/.gnupg"
host_gpg_agent_extra_socket="$(gpgconf --list-dir agent-extra-socket 2>/dev/null || true)"

cat > "$compose_env_file" <<EOF
MEM_LIMIT=${mem_limit}
CPU_LIMIT=${cpu_limit}
HOST_GIT_USER_NAME=$(escape_compose_env "$host_git_user_name")
HOST_GIT_USER_EMAIL=$(escape_compose_env "$host_git_user_email")
EOF

if [ -d "$host_gnupg_dir" ] && [ -S "$host_gpg_agent_extra_socket" ]; then
  cat > "$compose_host_file" <<EOF
services:
  devcontainer:
    volumes:
      - ${host_gnupg_dir}:/home/vscode/.host-gnupg:ro
      - ${host_gpg_agent_extra_socket}:/home/vscode/.gnupg/S.gpg-agent
EOF
else
  cat > "$compose_host_file" <<'EOF'
services:
  devcontainer:
    volumes: []
EOF

  printf '%s\n' \
    "[devcontainer] Host GPG forwarding disabled: missing ~/.gnupg or agent extra socket." \
    "[devcontainer] Commits inside the container will not be GPG-signed until the host agent is available." \
    >&2
fi
