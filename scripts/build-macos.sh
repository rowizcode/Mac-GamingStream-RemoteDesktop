#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_dir="$(cd "${script_dir}/.." && pwd)"
build_dir="${repo_dir}/build-macos"
install_deps=false
clean=false

usage() {
  echo "Usage: $0 [--install-deps] [--clean]"
}

while (($#)); do
  case "$1" in
    --install-deps) install_deps=true ;;
    --clean) clean=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

if [[ "$(uname -s)" != "Darwin" || "$(uname -m)" != "arm64" ]]; then
  echo "This build helper supports Apple Silicon macOS only." >&2
  exit 1
fi

if ! command -v xcrun >/dev/null 2>&1; then
  echo "Install Xcode Command Line Tools first: xcode-select --install" >&2
  exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
  echo "Homebrew is required. Install it from https://brew.sh and rerun." >&2
  exit 1
fi

formulas=(cmake node pkgconf icu4c@78 miniupnpc openssl@3 opus boost nlohmann-json)
if $install_deps; then
  brew install "${formulas[@]}"
else
  missing=()
  for formula in "${formulas[@]}"; do
    brew list --versions "$formula" >/dev/null 2>&1 || missing+=("$formula")
  done
  if ((${#missing[@]})); then
    echo "Missing Homebrew dependencies: ${missing[*]}" >&2
    echo "Rerun with --install-deps." >&2
    exit 1
  fi
fi

if $clean && [[ -d "$build_dir" ]]; then
  backup_dir="${repo_dir}/build-macos.previous.$(date +%Y%m%d-%H%M%S)"
  mv "$build_dir" "$backup_dir"
  echo "Moved the previous build to: $backup_dir"
fi

sdk_path="$(xcrun --sdk macosx --show-sdk-path)"
ffmpeg_tag="v2026.724.203728"
ffmpeg_sha256="f4f72fcef4180f18329351cc1080e3fa1a5a7d084fa1c52defa93586aac88f0f"
ffmpeg_cache="$build_dir/_deps/pinned-ffmpeg"
ffmpeg_dir="$ffmpeg_cache/ffmpeg"
ffmpeg_archive="$ffmpeg_cache/Darwin-arm64-ffmpeg.tar.gz"

if [[ ! -f "$ffmpeg_dir/lib/libavcodec.a" ]]; then
  mkdir -p "$ffmpeg_cache"
  download_tmp="${ffmpeg_archive}.download"
  curl --fail --location --retry 5 --retry-all-errors \
    "https://github.com/LizardByte/build-deps/releases/download/${ffmpeg_tag}/Darwin-arm64-ffmpeg.tar.gz" \
    --output "$download_tmp"
  actual_sha256="$(shasum -a 256 "$download_tmp" | awk '{print $1}')"
  if [[ "$actual_sha256" != "$ffmpeg_sha256" ]]; then
    rm -f -- "$download_tmp"
    echo "FFmpeg checksum mismatch: $actual_sha256" >&2
    exit 1
  fi
  mv "$download_tmp" "$ffmpeg_archive"
  tar -xzf "$ffmpeg_archive" -C "$ffmpeg_cache"
fi

export BUILD_VERSION="2026.8.14"
export BRANCH="mac-cloud-gaming"
export COMMIT="$(git -C "$repo_dir" rev-parse --short HEAD 2>/dev/null || printf source)"
export SHOULD_SIGN=false

cmake -S "$repo_dir" -B "$build_dir" \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=26.0 \
  -DCMAKE_OSX_SYSROOT="$sdk_path" \
  -DCMAKE_INSTALL_PREFIX="$build_dir/stage" \
  -DBUILD_DOCS=OFF \
  -DBUILD_TESTS=OFF \
  -DBUILD_WERROR=OFF \
  -DBOOST_USE_STATIC=OFF \
  -DOPUS_USE_STATIC=OFF \
  -DICU_ROOT="$(brew --prefix icu4c@78)" \
  -DFFMPEG_PREPARED_BINARIES="$ffmpeg_dir" \
  -DOPENSSL_ROOT_DIR="$(brew --prefix openssl@3)" \
  -DOpus_ROOT_DIR="$(brew --prefix opus)" \
  -DSUNSHINE_BUILD_HOMEBREW=OFF \
  -DSUNSHINE_ENABLE_TRAY=ON \
  -DSUNSHINE_PUBLISHER_NAME="Sunshine Mac Cloud Gaming contributors" \
  -DSUNSHINE_PUBLISHER_WEBSITE="https://github.com/rowizcode/Sunshine-Mac-Cloud-Gaming" \
  -DSUNSHINE_PUBLISHER_ISSUE_URL="https://github.com/rowizcode/Sunshine-Mac-Cloud-Gaming/issues"

cmake --build "$build_dir" --target sunshine web-ui --parallel "$(sysctl -n hw.ncpu)"
output_app="$build_dir/Sunshine.app"
if [[ ! -d "$output_app" ]]; then
  echo "CMake did not produce the expected app at $output_app" >&2
  exit 1
fi

# web-ui and sunshine are independent targets; copy the completed generated
# assets after both targets finish so target scheduling cannot omit the Web UI.
ditto "$build_dir/assets" "$output_app/Contents/Resources/assets"
xattr -rc "$output_app"
/usr/bin/strip -S "$output_app/Contents/MacOS/Sunshine"
codesign --force --deep --sign - \
  --entitlements "$repo_dir/hid_entitlements.plist" "$output_app"
codesign --verify --deep --strict --verbose=2 "$output_app"

# Also build the self-contained install tree used by the downloadable DMG.
# fixup_bundle() copies all non-system dylibs into Contents/Frameworks.
SHOULD_SIGN=false cmake --install "$build_dir"
stage_app="$build_dir/stage/Sunshine.app"
/usr/bin/strip -S "$stage_app/Contents/MacOS/Sunshine"
if [[ -d "$stage_app/Contents/Frameworks" ]]; then
  while IFS= read -r -d '' item; do
    codesign --force --sign - "$item"
  done < <(find -L "$stage_app/Contents/Frameworks" -type f -perm -111 -print0)
fi
codesign --force --deep --sign - \
  --entitlements "$repo_dir/hid_entitlements.plist" "$stage_app"
codesign --verify --deep --strict --verbose=2 "$stage_app"

echo
echo "Built: $output_app"
echo "Self-contained app: $stage_app"
echo "SHA-256: $(shasum -a 256 "$output_app/Contents/MacOS/Sunshine" | awk '{print $1}')"
echo "The build was not launched and did not modify the installed Sunshine app."
