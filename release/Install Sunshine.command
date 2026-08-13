#!/usr/bin/env bash
set -euo pipefail

release_dir="$(cd "$(dirname "$0")" && pwd)"
clear
echo "============================================================"
echo " Sunshine Mac Cloud Gaming - Easy Installer"
echo "============================================================"
echo
echo "This installs Sunshine, keeps existing settings, enables start"
echo "at login, and guides you through the three macOS permissions."
echo

"$release_dir/Support/install-macos.sh" \
  --app "$release_dir/Sunshine.app" \
  --recommended-config "$release_dir/Support/sunshine.conf.example" \
  --interactive
