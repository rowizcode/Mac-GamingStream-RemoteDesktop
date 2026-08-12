#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "${script_dir}/.." && pwd)"
source_app=""
target_app=""
recommended_config=""
install_autostart=true
interactive=false

usage() {
  cat <<'EOF'
Usage: install-macos.sh [options]

Options:
  --app PATH                 Install this Sunshine.app.
  --target PATH              Install to this path instead of Applications.
  --recommended-config PATH  Copy this config only when no config exists.
  --no-autostart             Do not start Sunshine automatically at login.
  --interactive              Guide the user through macOS permissions.
EOF
}

while (($#)); do
  case "$1" in
    --app|--target|--recommended-config)
      [[ $# -ge 2 ]] || { echo "$1 requires a path" >&2; exit 2; }
      case "$1" in
        --app) source_app="$2" ;;
        --target) target_app="$2" ;;
        --recommended-config) recommended_config="$2" ;;
      esac
      shift
      ;;
    --no-autostart) install_autostart=false ;;
    --interactive) interactive=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "This installer supports Apple Silicon macOS only." >&2
  exit 1
fi

macos_major="$(sw_vers -productVersion | cut -d. -f1)"
if [[ ! "$macos_major" =~ ^[0-9]+$ ]] || ((macos_major < 26)); then
  echo "This release requires macOS 26 or later." >&2
  echo "Update macOS in System Settings, then run the installer again." >&2
  exit 1
fi

if [[ -z "$source_app" ]]; then
  for candidate in \
    "$repo_dir/build-macos/stage/Sunshine.app" \
    "$repo_dir/build-macos/Sunshine.app" \
    "$repo_dir/Sunshine.app"; do
    if [[ -x "$candidate/Contents/MacOS/Sunshine" ]]; then
      source_app="$candidate"
      break
    fi
  done
fi

if [[ ! -d "$source_app" || ! -x "$source_app/Contents/MacOS/Sunshine" ]]; then
  echo "Sunshine.app was not found. Download the DMG release or build the app first." >&2
  exit 1
fi

if [[ -z "$target_app" ]]; then
  if [[ -w /Applications ]]; then
    target_app="/Applications/Sunshine.app"
  else
    mkdir -p "$HOME/Applications"
    target_app="$HOME/Applications/Sunshine.app"
  fi
fi

if [[ -z "$recommended_config" ]]; then
  for candidate in \
    "$script_dir/sunshine.conf.example" \
    "$repo_dir/config/sunshine.conf.example"; do
    if [[ -f "$candidate" ]]; then
      recommended_config="$candidate"
      break
    fi
  done
fi

entitlements=""
for candidate in \
  "$script_dir/hid_entitlements.plist" \
  "$repo_dir/hid_entitlements.plist"; do
  if [[ -f "$candidate" ]]; then
    entitlements="$candidate"
    break
  fi
done
if [[ -z "$entitlements" ]]; then
  echo "The HID entitlement file is missing from this installer." >&2
  exit 1
fi

codesign --verify --deep --strict "$source_app"

timestamp="$(date +%Y%m%d-%H%M%S)"
target_dir="$(dirname "$target_app")"
stage_app="${target_dir}/.Sunshine.installing.${timestamp}.app"
backup_app="${target_dir}/Sunshine.backup.${timestamp}.app"
mkdir -p "$target_dir"

echo "Stopping Sunshine if it is already running..."
pkill -x Sunshine 2>/dev/null || true
for _ in {1..30}; do
  pgrep -x Sunshine >/dev/null 2>&1 || break
  sleep 0.1
done

ditto "$source_app" "$stage_app"
xattr -rc "$stage_app"

# The release is ad-hoc signed. Re-sign after copying so quarantine removal and
# any path change cannot leave a stale signature.
if [[ -d "$stage_app/Contents/Frameworks" ]]; then
  while IFS= read -r -d '' item; do
    codesign --force --sign - "$item"
  done < <(find -L "$stage_app/Contents/Frameworks" -type f -perm -111 -print0)
fi
codesign --force --deep --sign - \
  --entitlements "$entitlements" "$stage_app"
codesign --verify --deep --strict --verbose=2 "$stage_app"

if [[ -d "$target_app" ]]; then
  echo "Backing up the previous app to: $backup_app"
  mv "$target_app" "$backup_app"
fi

if ! mv "$stage_app" "$target_app"; then
  if [[ -d "$backup_app" && ! -e "$target_app" ]]; then
    mv "$backup_app" "$target_app"
  fi
  echo "Install failed. The previous app was restored." >&2
  exit 1
fi

config_dir="$HOME/.config/sunshine"
config_file="$config_dir/sunshine.conf"
mkdir -p "$config_dir"
if [[ ! -s "$config_file" && -n "$recommended_config" && -f "$recommended_config" ]]; then
  cp "$recommended_config" "$config_file"
  chmod 600 "$config_file"
  echo "Installed the recommended starter configuration."
else
  echo "Kept the existing Sunshine configuration."
fi

if $install_autostart; then
  agent_dir="$HOME/Library/LaunchAgents"
  agent_file="$agent_dir/dev.lizardbyte.app.Sunshine.plist"
  mkdir -p "$agent_dir"
  if [[ -f "$agent_file" ]]; then
    cp -p "$agent_file" "${agent_file}.backup.${timestamp}"
  fi
  plutil -create xml1 "$agent_file"
  plutil -insert Label -string dev.lizardbyte.app.Sunshine "$agent_file"
  plutil -insert ProgramArguments -json "[\"/usr/bin/open\",\"$target_app\"]" "$agent_file"
  plutil -insert RunAtLoad -bool true "$agent_file"
  plutil -insert ProcessType -string Interactive "$agent_file"
  launchctl bootout "gui/$(id -u)" "$agent_file" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$agent_file"
  launchctl enable "gui/$(id -u)/dev.lizardbyte.app.Sunshine"
fi

open "$target_app"
sleep 2

echo
echo "Installed Sunshine at: $target_app"
echo "Runtime data is kept privately at: $config_dir"
echo "Sunshine will start automatically after this user logs in."

if $interactive; then
  echo
  echo "STEP 1 OF 3 - Accessibility"
  echo "Turn Sunshine ON in the System Settings window, then return here."
  open 'x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility'
  read -r -p "Press Return after Sunshine is enabled... " _

  echo
  echo "STEP 2 OF 3 - Screen & System Audio Recording"
  echo "Turn Sunshine ON, then return here."
  open 'x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture'
  read -r -p "Press Return after Sunshine is enabled... " _

  pkill -x Sunshine 2>/dev/null || true
  sleep 1
  open "$target_app"
  sleep 3

  echo
  echo "STEP 3 OF 3 - Create the Web UI account"
  echo "Your browser will open https://localhost:47990."
  echo "The local certificate warning is expected. Create a NEW Sunshine username/password."
  open 'https://localhost:47990'
fi

boot_args="$(sysctl -n kern.bootargs 2>/dev/null || true)"
echo
if [[ " $boot_args " == *" amfi_get_out_of_my_way=1 "* ]]; then
  echo "Gamepad security setup: READY. Reconnect Moonlight before opening a game."
else
  echo "Gamepad security setup: NOT ENABLED."
  echo "Video, audio, keyboard and mouse still work. For gamepad, read GAMEPAD-SETUP.html."
fi

echo
echo "Installation is complete. This installer did not change SIP, AMFI, NVRAM,"
echo "the startup security policy, saved Sunshine passwords, or Moonlight pairing data."

if $interactive; then
  read -r -p "Press Return to close this window... " _
fi
