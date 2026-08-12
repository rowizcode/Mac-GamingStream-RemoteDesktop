# Sunshine Mac Cloud Gaming

An experimental Sunshine derivative for turning an Apple Silicon Mac into a
low-latency Moonlight host. It packages the macOS work that was tested on an M4
Mac mini: native screen/system-audio capture, VideoToolbox H.264/HEVC encoding,
remote keyboard/mouse input, and an Xbox-compatible virtual gamepad.

This repository is source code, not an official Sunshine or Lumen release.
It is derived from [Sunshine](https://github.com/LizardByte/Sunshine) and
[Lumen](https://github.com/trollzem/Lumen). See [NOTICE](NOTICE) and
[LICENSE](LICENSE).

## What works in the tested setup

- Moonlight streams the currently active physical desktop. The default example
  config deliberately keeps `virtual_display = disabled`.
- VideoToolbox hardware encoding with H.264 and HEVC, including 60/90/120 FPS
  client requests when the display and game can sustain them.
- Native system-audio capture.
- Relative and absolute mouse movement, clicks, scrolling, and keyboard input.
- Xbox-compatible virtual HID controller input in Steam games such as Skater XL.
- Multiple controller slots use Moonlight's `globalIndex`; allocation returns
  success correctly instead of orphaning all slots after slot 0.

## Tested platform

- Apple Silicon Mac (tested on M4 Mac mini)
- macOS 26.6 (build 25G72)
- Command Line Tools / Apple clang 17
- Moonlight on iOS
- Wired Ethernet on the host

Other Apple Silicon generations and macOS 14+ may work, but have not yet been
validated by this project. Intel Macs are not supported by the supplied scripts.

## Important gamepad security warning

The virtual controller uses `IOHIDUserDevice` and Apple's restricted
`com.apple.developer.hid.virtual.device` entitlement. The tested ad-hoc build
requires AMFI to be disabled with the boot argument
`amfi_get_out_of_my_way=1`. This reduces an important macOS security layer.

The scripts in this repository **never change SIP, AMFI, NVRAM, or the startup
security policy automatically**. Read [docs/GAMEPAD.md](docs/GAMEPAD.md) and make
that decision yourself. Streaming, audio, keyboard, and mouse can still be used
without enabling the virtual gamepad.

## Quick build

Install Xcode Command Line Tools and Homebrew, then run:

```bash
./scripts/build-macos.sh --install-deps
```

The app is produced at `build-macos/Sunshine.app`. The build uses a pinned
Apple-Silicon FFmpeg package and verifies its SHA-256 checksum.

Install it after reviewing the security warning:

```bash
./scripts/install-macos.sh
```

The installer:

- backs up an existing `/Applications/Sunshine.app`;
- never deletes or replaces `~/.config/sunshine`;
- ad-hoc signs the app with the included HID entitlements;
- optionally installs a per-user LaunchAgent so Sunshine starts after login.

Then grant Sunshine these permissions in System Settings → Privacy & Security:

1. Screen & System Audio Recording
2. Accessibility

Quit and reopen Sunshine after changing permissions. Open the local web UI at
<https://localhost:47990>, create credentials, pair Moonlight, and connect to the
Desktop entry.

## Recommended starting configuration

Copy only the settings you understand from
[config/sunshine.conf.example](config/sunshine.conf.example). Do not overwrite an
existing config blindly.

On Moonlight iOS, start with:

- resolution matching the phone or display;
- 60 FPS while validating the setup, then 90/120 FPS;
- HEVC on compatible devices, H.264 when minimum latency matters more;
- a sensible bitrate for the RF environment instead of assuming a speed-test
  result guarantees low jitter.

Sunshine's `max_bitrate = 0` leaves the host uncapped; the Moonlight bitrate still
controls the requested stream bitrate.

## Documentation

- [Setup and permissions](docs/SETUP.md)
- [Virtual gamepad and security](docs/GAMEPAD.md)
- [Performance tuning](docs/PERFORMANCE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Architecture and source provenance](docs/ARCHITECTURE.md)

## Project status

Experimental. The tested machine has AMFI disabled and, during development, SIP
was also disabled. Lumen documents that its virtual HID path needs AMFI rather
than SIP; this repository does not claim SIP is required. Keep backups, review
the source, and do not deploy this on a Mac that must retain the default security
posture.

## License

GPL-3.0-only. Third-party components keep their own notices and licenses.
