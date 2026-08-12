#!/usr/bin/env bash
set -u

app="/Applications/Sunshine.app"
binary="$app/Contents/MacOS/Sunshine"
log_file="${HOME}/.config/sunshine/sunshine.log"

echo "== System =="
sw_vers
uname -m

echo
echo "== Security state (read-only) =="
csrutil status 2>&1 || true
nvram boot-args 2>&1 || true

echo
echo "== Installed app =="
if [[ -x "$binary" ]]; then
  echo "$binary"
  shasum -a 256 "$binary"
  codesign --verify --deep --strict --verbose=2 "$app" 2>&1 || true
  codesign -d --entitlements - "$app" 2>&1 || true
else
  echo "Sunshine is not installed at $app"
fi

echo
echo "== Process and ports =="
pgrep -alf '/Sunshine.app/Contents/MacOS/Sunshine' || true
lsof -nP -iTCP:47990 -sTCP:LISTEN 2>/dev/null || true

echo
echo "== Relevant recent log lines =="
if [[ -f "$log_file" ]]; then
  if command -v rg >/dev/null 2>&1; then
    rg 'Accessibility|IOHIDUserDevice|Gamepad|Found (H\.264|HEVC)|Creating encoder|virtual display' "$log_file" | tail -n 120
  else
    grep -E 'Accessibility|IOHIDUserDevice|Gamepad|Found (H\.264|HEVC)|Creating encoder|virtual display' "$log_file" | tail -n 120
  fi
else
  echo "No log found at $log_file"
fi

echo
echo "This diagnostic does not change the Mac."
