#!/usr/bin/env bash
# One-time (or after pod/cache issues) iOS dependency setup.
# Uses HTTP/1.1 for git clones — avoids CocoaPods Firebase clone failures
# (curl 56 / HTTP/2 CANCEL) on some networks and VPNs.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

if [[ ! -f config/dev.json ]]; then
  echo "Missing config/dev.json — run: cp config/dev.example.json config/dev.json"
  exit 1
fi

echo "→ Flutter pub get"
fvm flutter pub get

echo "→ Precache iOS engine artifacts (first run may take several minutes)"
fvm flutter precache --ios

export GIT_CONFIG_COUNT=1
export GIT_CONFIG_KEY_0=http.version
export GIT_CONFIG_VALUE_0=HTTP/1.1

echo "→ CocoaPods (ios/)"
cd ios
pod install
cd "$ROOT"

echo "✓ iOS setup complete. Launch with VS Code config \"dth dev\" or: make run-dev"
