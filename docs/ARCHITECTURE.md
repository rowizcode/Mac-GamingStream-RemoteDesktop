# Architecture and provenance

## Pipeline

```text
Moonlight input ──► Sunshine input layer
                      ├─► CGEvent keyboard/mouse injection
                      └─► IOHIDUserDevice Xbox-compatible virtual gamepad

Physical display ─► macOS capture ─► FFmpeg VideoToolbox H.264/HEVC
System audio ──────► native macOS audio capture ─► Opus
Encoded video/audio ─────────────────────────────► Moonlight
```

## Source lineage

This snapshot combines:

- Sunshine's GameStream protocol host, web UI, networking, codec integration,
  and modern cross-platform configuration;
- Lumen's macOS capture/audio/input direction and virtual HID work;
- local fixes for current-desktop capture, Accessibility diagnostics, Xbox-style
  mapping, and correct multi-slot gamepad allocation.

The exact upstream history was not cleanly representable as a small patch because
the working tree combined two diverged source generations. The public repository
therefore contains a reviewed source snapshot with build/cache files removed,
plus explicit attribution and the original GPL license.

## Reproducible dependency

The Apple Silicon FFmpeg build is pinned to LizardByte/build-deps release
`v2026.724.203728`:

```text
Darwin-arm64-ffmpeg.tar.gz
SHA-256 f4f72fcef4180f18329351cc1080e3fa1a5a7d084fa1c52defa93586aac88f0f
```

## Current limitations

- Apple Silicon only in the supplied tooling.
- No Apple notarization or Developer ID distribution yet.
- Restricted virtual-HID entitlements require a non-default security state for
  ad-hoc builds.
- No gamepad touchpad, motion, or rumble forwarding in the Xbox-compatible
  profile.
- Clean-machine validation is still needed on M1/M2/M3/M5 and stable macOS
  releases.
