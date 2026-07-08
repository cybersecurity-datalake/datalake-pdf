#!/bin/bash

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOGDIR=/tmp
PIDSFILE="${LOGDIR}/devcontainer-latex-pids"
WATCHERS_LOG="${LOGDIR}/devcontainer-watchers.log"
OUTPUT_DIR="${WORKSPACE_DIR}/output"
LOGFILE="${LOGDIR}/latex-watch-main.log"

stop_existing_watchers() {
  if [ ! -f "$PIDSFILE" ]; then
    return
  fi

  while IFS= read -r pid; do
    if [ -z "${pid}" ]; then
      continue
    fi

    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
      echo "$(date -Iseconds) Stopped existing watcher PID $pid" >> "$WATCHERS_LOG"
    fi
  done < "$PIDSFILE"

  rm -f "$PIDSFILE"
}

echo "$(date -Iseconds) Starting latexmk watchers..." > "$WATCHERS_LOG"

MAIN_TEX="${WORKSPACE_DIR}/src/main.tex"

if [ ! -f "$MAIN_TEX" ]; then
  echo "$(date -Iseconds) No src/main.tex found; no watcher started." >> "$WATCHERS_LOG"
  exit 0
fi

stop_existing_watchers
mkdir -p "$OUTPUT_DIR"
echo "$(date -Iseconds) Starting watcher for $MAIN_TEX -> $LOGFILE" >> "$WATCHERS_LOG"
(
  cd "$WORKSPACE_DIR" || exit 1
  exec nohup latexmk -pdf -pvc -view=none -interaction=nonstopmode -file-line-error -halt-on-error -outdir="$OUTPUT_DIR" src/main.tex > "$LOGFILE" 2>&1 < /dev/null
) &
PID=$!

if [ -n "${PID:-}" ]; then
  echo "$PID" >> "$PIDSFILE"
  echo "$(date -Iseconds) Started PID $PID for $MAIN_TEX" >> "$WATCHERS_LOG"
fi

exit 0
