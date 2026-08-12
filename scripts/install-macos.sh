#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "${script_dir}/.." && pwd)"
source_app="${repo_dir}/build-macos/Sunshine.app"
target_app="/Applications/Sunshine.app"
install_autostart=true

usage() {
  echo "Usage: $0 [--app PATH] [--no-autostart]"
}

while (($#)); do
  case "$1" in
    --app)
      [[ $# -ge 2 ]] || { echo "--app requires a path" >&2; exit 2; }
      source_app="$2"
      shift
      ;;
    --no-autostart) install_autostart=false ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "This installer supports Apple Silicon macOS only." >&2
  exit 1
fi

if [[ ! -d "$source_app" || ! -x "$source_app/Contents/MacOS/Sunshine" ]]; then
  echo "Sunshine.app not found at: $source_app" >&2
  echo "Run ./scripts/build-macos.sh first." >&2
  exit 1
fi

codesign --verify --deep --strict "$source_app"

timestamp="$(date +%Y%m%d-%H%M%S)"
if [[ -d "$target_app" ]]; then
  backup_app="/Applications/Sunshine.backup.${timestamp}.app"
  echo "Backing up the installed app to: $backup_app"
  ditto "$target_app" "$backup_app"
fi

echo "Stopping the running Sunshine process, if any..."
pkill -x Sunshine 2>/dev/null || true
for _ in {1..20}; do
  pgrep -x Sunshine >/dev/null 2>&1 || break
  sleep 0.1
done

stage_app="/Applications/.Sunshine.installing.${timestamp}.app"
ditto "$source_app" "$stage_app"
xattr -rc "$stage_app"
codesign --force --deep --sign - \
  --entitlements "$repo_dir/hid_entitlements.plist" "$stage_app"
codesign --verify --deep --strict --verbose=2 "$stage_app"

replaced_app=""
if [[ -d "$target_app" ]]; then
  replaced_app="/Applications/.Sunshine.replaced.${timestamp}.app"
  mv "$target_app" "$replaced_app"
fi
if ! mv "$stage_app" "$target_app"; then
  if [[ -n "$replaced_app" && -d "$replaced_app" ]]; then
    mv "$replaced_app" "$target_app"
  fi
  echo "Install failed; the previous app was restored." >&2
  exit 1
fi
if [[ -n "$replaced_app" ]]; then
  echo "The previous app copy remains at: $replaced_app"
fi

if $install_autostart; then
  agent_dir="${HOME}/Library/LaunchAgents"
  agent_file="${agent_dir}/dev.lizardbyte.app.Sunshine.plist"
  mkdir -p "$agent_dir"
  if [[ -f "$agent_file" ]]; then
    cp -p "$agent_file" "${agent_file}.backup.${timestamp}"
  fi
  plutil -create xml1 "$agent_file"
  plutil -insert Label -string dev.lizardbyte.app.Sunshine "$agent_file"
  plutil -insert ProgramArguments -json '["/usr/bin/open","-a","Sunshine"]' "$agent_file"
  plutil -insert RunAtLoad -bool true "$agent_file"
  plutil -insert ProcessType -string Interactive "$agent_file"
  launchctl bootout "gui/$(id -u)" "$agent_file" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$agent_file"
  launchctl enable "gui/$(id -u)/dev.lizardbyte.app.Sunshine"
fi

echo "Installed: $target_app"
echo "Preserved runtime data: ${HOME}/.config/sunshine"
echo "Open System Settings and grant Screen & System Audio Recording and Accessibility."
echo "The installer did not change SIP, AMFI, NVRAM, or boot arguments."
