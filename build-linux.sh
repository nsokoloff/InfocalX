#!/usr/bin/env bash
# Build Infocal for a Garmin device on Linux and optionally copy it to the watch.
#
# Usage: ./build-linux.sh [device] [mount-point-of-watch]
#   device defaults to fenix7pro (use fenix7pronowifi if your unit has no Wi-Fi)
#   APP_DIR=companions/clock APP_NAME=InfocalClock ./build-linux.sh   builds a companion app instead
#
# Requirements:
#   - Connect IQ SDK installed via Garmin's SDK Manager (with the fenix 7 Pro device downloaded)
#   - Java (JRE 8+)
#   - A developer key (generated below if missing)
set -euo pipefail

DEVICE="${1:-fenix7pro}"
MOUNT="${2:-}"
cd "$(dirname "$0")"

# SDK Manager stores the active SDK path here.
SDK_CFG="$HOME/.Garmin/ConnectIQ/current-sdk.cfg"
if [[ -z "${CIQ_SDK:-}" ]]; then
  [[ -f "$SDK_CFG" ]] || { echo "SDK not found. Set CIQ_SDK=/path/to/connectiq-sdk or install via SDK Manager." >&2; exit 1; }
  CIQ_SDK="$(cat "$SDK_CFG")"
  CIQ_SDK="${CIQ_SDK%/bin*}"
fi

KEY="${CIQ_KEY:-$HOME/.Garmin/developer_key.der}"
if [[ ! -f "$KEY" ]]; then
  echo "Generating developer key at $KEY (keep it, you need the same key for future updates)"
  mkdir -p "$(dirname "$KEY")"
  openssl genrsa -out "$KEY.pem" 4096
  openssl pkcs8 -topk8 -inform PEM -outform DER -in "$KEY.pem" -out "$KEY" -nocrypt
fi

mkdir -p bin
APP_DIR="${APP_DIR:-.}"
APP_NAME="${APP_NAME:-Infocal}"
OUT="bin/$APP_NAME-$DEVICE.prg"
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar "$CIQ_SDK/bin/monkeybrains.jar" -d "$DEVICE" -f "$APP_DIR/monkey.jungle" -o "$OUT" -y "$KEY" -w -l 0
echo "Built $OUT"

if [[ -n "$MOUNT" ]]; then
  APPS="$MOUNT/GARMIN/APPS"
  [[ -d "$APPS" ]] || { echo "$APPS not found - is the watch mounted there?" >&2; exit 1; }
  cp "$OUT" "$APPS/$APP_NAME.prg"
  echo "Copied to $APPS/$APP_NAME.prg - eject the watch, then pick the watch face on the device."
fi
