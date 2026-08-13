#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "${script_dir}/.." && pwd)"
build_dir="$repo_dir/build-macos"
stage_app="$build_dir/stage/Sunshine.app"
dist_dir="$repo_dir/dist"
version="2026.8.14"

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "DMG packaging supports Apple Silicon macOS only." >&2
  exit 1
fi

if [[ ! -x "$build_dir/Sunshine.app/Contents/MacOS/Sunshine" ]]; then
  echo "Build the project first with ./scripts/build-macos.sh --install-deps" >&2
  exit 1
fi

if [[ ! -x "$stage_app/Contents/MacOS/Sunshine" ]]; then
  echo "The self-contained app is missing. Rerun ./scripts/build-macos.sh" >&2
  exit 1
fi
codesign --verify --deep --strict --verbose=2 "$stage_app"
if [[ "$(defaults read "$stage_app/Contents/Info" LSMinimumSystemVersion)" != "26.0" ]]; then
  echo "The staged app does not declare the expected macOS 26 minimum." >&2
  exit 1
fi

if find "$stage_app/Contents" -type f -perm -111 -print0 \
  | xargs -0 otool -L 2>/dev/null \
  | /usr/bin/grep -Eq '/opt/homebrew|/usr/local'; then
  echo "The packaged executable still depends on a package-manager path." >&2
  exit 1
fi

mkdir -p "$dist_dir"
dmg_root="$(mktemp -d "$build_dir/dmg-root.XXXXXX")"
cleanup() {
  case "$dmg_root" in
    "$build_dir"/dmg-root.*) rm -rf -- "$dmg_root" ;;
  esac
}
trap cleanup EXIT

ditto "$stage_app" "$dmg_root/Sunshine.app"
ditto "$repo_dir/release/Install Sunshine.command" "$dmg_root/Install Sunshine.command"
mkdir -p "$dmg_root/Support"
ditto "$repo_dir/scripts/install-macos.sh" "$dmg_root/Support/install-macos.sh"
ditto "$repo_dir/config/sunshine.conf.example" "$dmg_root/Support/sunshine.conf.example"
ditto "$repo_dir/hid_entitlements.plist" "$dmg_root/Support/hid_entitlements.plist"
ditto "$repo_dir/release/START-HERE.html" "$dmg_root/START-HERE.html"
ditto "$repo_dir/release/GAMEPAD-SETUP.html" "$dmg_root/GAMEPAD-SETUP.html"
ditto "$repo_dir/LICENSE" "$dmg_root/LICENSE.txt"
chmod +x "$dmg_root/Install Sunshine.command" "$dmg_root/Support/install-macos.sh"
ln -s /Applications "$dmg_root/Applications"

output="$dist_dir/Sunshine-Mac-Cloud-Gaming-${version}-Apple-Silicon.dmg"
if [[ -e "$output" ]]; then
  mv "$output" "${output}.previous.$(date +%Y%m%d-%H%M%S)"
fi
hdiutil create \
  -volname "Sunshine Mac Cloud Gaming" \
  -srcfolder "$dmg_root" \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$output"
hdiutil verify "$output"

echo
echo "Created: $output"
echo "SHA-256: $(shasum -a 256 "$output" | awk '{print $1}')"
echo "This DMG is ad-hoc signed and not Apple-notarized."
