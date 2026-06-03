#!/usr/bin/env bash
set -euo pipefail

# Build two release PRGs for sideload distribution:
# - old: targets an older CIQ device (default: fr245)
# - new: targets a newer CIQ device (default: vivoactive5)
#
# Usage:
#   scripts/build_release_prgs.sh [old_device_id] [new_device_id]
#
# Example:
#   scripts/build_release_prgs.sh fr245 vivoactive5

usage() {
  cat <<'EOF'
Build two release PRGs for sideload distribution.

Usage:
  scripts/build_release_prgs.sh [old_device_id] [new_device_id]

Defaults:
  old_device_id = fr245
  new_device_id = vivoactive5

Notes:
  - MB_HOME is auto-detected from ~/.Garmin/ConnectIQ/current-sdk.cfg or ~/.Garmin/ConnectIQ/Sdks.
  - MB_PRIVATE_KEY defaults to <project>/garmin_key.der.
  - APP_NAME defaults to GarminSD (override with APP_NAME env var).
EOF
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage
  exit 0
fi

if [[ $# -gt 2 ]]; then
  usage
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CFG_FILE="$ROOT_DIR/mb_runner.cfg"
OUT_DIR="$ROOT_DIR/build"

OLD_DEVICE="${1:-fr245}"
NEW_DEVICE="${2:-vivoactive5}"
APP_NAME="${APP_NAME:-GarminSD}"

if [[ "$OLD_DEVICE" == -* || "$NEW_DEVICE" == -* ]]; then
  echo "Invalid device id argument."
  usage
  exit 1
fi

# Prefer explicit MB_HOME. If missing, detect SDK from common locations.
if [[ -z "${MB_HOME:-}" ]]; then
  if [[ -f "$HOME/.Garmin/ConnectIQ/current-sdk.cfg" ]]; then
    MB_HOME="$(tr -d '\r\n' < "$HOME/.Garmin/ConnectIQ/current-sdk.cfg")"
  fi

  if [[ -z "${MB_HOME:-}" || ! -x "${MB_HOME}/bin/monkeyc" ]]; then
    MB_HOME="$(find "$HOME/.Garmin/ConnectIQ/Sdks" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | sort -V | tail -n 1)"
  fi
fi

if [[ -z "${MB_HOME:-}" || ! -x "${MB_HOME}/bin/monkeyc" ]]; then
  echo "Unable to locate a valid SDK for MB_HOME."
  echo "Set MB_HOME manually, for example:"
  echo "  export MB_HOME=\"$HOME/.Garmin/ConnectIQ/Sdks/<sdk-folder>\""
  exit 1
fi

export MB_HOME

# Prefer explicit MB_PRIVATE_KEY. If missing, default to project key.
if [[ -z "${MB_PRIVATE_KEY:-}" ]]; then
  MB_PRIVATE_KEY="$ROOT_DIR/garmin_key.der"
fi

if [[ ! -f "${MB_PRIVATE_KEY}" ]]; then
  echo "Signing key not found: ${MB_PRIVATE_KEY}"
  echo "Set MB_PRIVATE_KEY manually, for example:"
  echo "  export MB_PRIVATE_KEY=\"$HOME/.Garmin/ConnectIQ/developer_key.der\""
  exit 1
fi

export MB_PRIVATE_KEY

mkdir -p "$OUT_DIR"

# Keep the original config intact after the script exits.
CFG_BACKUP=""
CFG_EXISTED="false"
if [[ -f "$CFG_FILE" ]]; then
  CFG_BACKUP="$(mktemp)"
  cp "$CFG_FILE" "$CFG_BACKUP"
  CFG_EXISTED="true"
fi

restore_cfg() {
  if [[ "$CFG_EXISTED" == "true" ]]; then
    cp "$CFG_BACKUP" "$CFG_FILE"
    rm -f "$CFG_BACKUP"
  else
    rm -f "$CFG_FILE"
  fi
}
trap restore_cfg EXIT

write_cfg() {
  local device="$1"
  cat > "$CFG_FILE" <<EOF
APP_NAME="$APP_NAME"
TARGET_DEVICE="$device"
EOF
}

build_variant() {
  local device="$1"
  local suffix="$2"

  echo "Building $suffix variant for device: $device"
  write_cfg "$device"

  (
    cd "$ROOT_DIR"
    ./mb_runner.sh build
  )

  local built_prg="$ROOT_DIR/${APP_NAME}.prg"
  local out_prg="$OUT_DIR/${APP_NAME}_${suffix}.prg"

  if [[ ! -f "$built_prg" ]]; then
    echo "Expected output not found: $built_prg"
    exit 1
  fi

  cp "$built_prg" "$out_prg"
  echo "Wrote $out_prg"
}

build_variant "$OLD_DEVICE" "old"
build_variant "$NEW_DEVICE" "new"

echo "Done."
echo "Release binaries:"
echo "  $OUT_DIR/${APP_NAME}_old.prg"
echo "  $OUT_DIR/${APP_NAME}_new.prg"
