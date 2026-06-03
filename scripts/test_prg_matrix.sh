#!/usr/bin/env bash
set -euo pipefail

# Test a PRG against multiple simulator device IDs.
#
# Usage:
#   scripts/test_prg_matrix.sh <path-to-prg> <device_id> [device_id ...]
#
# Example:
#   scripts/test_prg_matrix.sh build/GarminSD_old.prg fr245 fr245m fr945

usage() {
  cat <<'EOF'
Run one PRG on multiple Garmin simulator device IDs.

Usage:
  scripts/test_prg_matrix.sh <path-to-prg> <device_id> [device_id ...]

Environment:
  DEVICE_TIMEOUT_SEC   Per-device timeout in seconds (default: 20)
  LOG_DIR              Directory for per-device logs (default: build/test_logs/<timestamp>)

Examples:
  scripts/test_prg_matrix.sh build/GarminSD_old.prg fr245 fr245m fr945
  scripts/test_prg_matrix.sh build/GarminSD_new.prg vivoactive5 fr255 fr965
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PRG_PATH="$1"
shift
DEVICES=("$@")
DEVICE_TIMEOUT_SEC="${DEVICE_TIMEOUT_SEC:-20}"
RUN_STAMP="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="${LOG_DIR:-$ROOT_DIR/build/test_logs/$RUN_STAMP}"

if [[ "$PRG_PATH" != /* ]]; then
  PRG_PATH="$ROOT_DIR/$PRG_PATH"
fi

if [[ ! -f "$PRG_PATH" ]]; then
  echo "PRG not found: $PRG_PATH"
  exit 1
fi

mkdir -p "$LOG_DIR"

# Resolve MB_HOME from env or Garmin default location.
if [[ -z "${MB_HOME:-}" ]]; then
  if [[ -f "$HOME/.Garmin/ConnectIQ/current-sdk.cfg" ]]; then
    MB_HOME="$(tr -d '\r\n' < "$HOME/.Garmin/ConnectIQ/current-sdk.cfg")"
  fi

  if [[ -z "${MB_HOME:-}" || ! -x "$MB_HOME/bin/monkeydo" ]]; then
    MB_HOME="$(find "$HOME/.Garmin/ConnectIQ/Sdks" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -V | tail -n 1)"
  fi
fi

if [[ -z "${MB_HOME:-}" || ! -x "$MB_HOME/bin/monkeydo" || ! -x "$MB_HOME/bin/connectiq" ]]; then
  echo "Unable to locate SDK tools (connectiq/monkeydo)."
  echo "Set MB_HOME manually, for example:"
  echo "  export MB_HOME=\"$HOME/.Garmin/ConnectIQ/Sdks/<sdk-folder>\""
  exit 1
fi

export MB_HOME

SIM_STARTED_BY_SCRIPT="false"
if ! pgrep -f "/bin/simulator" >/dev/null 2>&1; then
  "$MB_HOME/bin/connectiq" >/tmp/connectiq_test_matrix.log 2>&1 &
  SIM_PID=$!
  SIM_STARTED_BY_SCRIPT="true"
  # Give simulator time to initialize its shell socket.
  sleep 2
fi

PASS_DEVICES=()
FAIL_DEVICES=()

for dev in "${DEVICES[@]}"; do
  echo "===== Testing ${dev} ====="
  LOG_FILE="$LOG_DIR/${dev}.log"

  # monkeydo may keep running while app logs stream, so enforce a timeout.
  set +e
  OUTPUT="$(timeout "${DEVICE_TIMEOUT_SEC}" "$MB_HOME/bin/monkeydo" "$PRG_PATH" "$dev" 2>&1)"
  STATUS=$?
  set -e

  printf '%s\n' "$OUTPUT" > "$LOG_FILE"

  if echo "$OUTPUT" | grep -qE "initialize|onStart|on_layout|GarminSD"; then
    if [[ $STATUS -eq 124 ]]; then
      echo "PASS: ${dev} (launch confirmed; monitor window ended at ${DEVICE_TIMEOUT_SEC}s)"
    else
      echo "PASS: ${dev}"
    fi
    echo "  log: $LOG_FILE"
    PASS_DEVICES+=("$dev")
  elif [[ $STATUS -eq 0 ]]; then
    echo "WARN: ${dev} exited cleanly but no obvious app-start markers."
    echo "$OUTPUT" | sed -n '1,25p'
    echo "  log: $LOG_FILE"
    PASS_DEVICES+=("$dev")
  else
    echo "FAIL: ${dev}"
    echo "$OUTPUT" | sed -n '1,40p'
    echo "  log: $LOG_FILE"
    FAIL_DEVICES+=("$dev")
  fi

  echo
  # Small pause between device launches to reduce simulator timing issues.
  sleep 1
done

echo "===== Summary ====="
echo "PRG: $PRG_PATH"
echo "Logs: $LOG_DIR"
echo "Passed: ${#PASS_DEVICES[@]}"
if [[ ${#PASS_DEVICES[@]} -gt 0 ]]; then
  echo "  ${PASS_DEVICES[*]}"
fi

echo "Failed: ${#FAIL_DEVICES[@]}"
if [[ ${#FAIL_DEVICES[@]} -gt 0 ]]; then
  echo "  ${FAIL_DEVICES[*]}"
fi

if [[ "$SIM_STARTED_BY_SCRIPT" == "true" ]]; then
  kill "$SIM_PID" >/dev/null 2>&1 || true
fi

if [[ ${#FAIL_DEVICES[@]} -gt 0 ]]; then
  exit 2
fi
