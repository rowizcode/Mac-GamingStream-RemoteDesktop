# Sunshine Mac Cloud Gaming

Turn an Apple Silicon Mac into a low-latency Moonlight host. This experimental
Sunshine derivative streams the Mac's **current physical desktop**, system
audio, keyboard/mouse/touch input, and—after an optional security step—a virtual
Xbox-compatible controller.

> This is a community build derived from
> [Sunshine](https://github.com/LizardByte/Sunshine) and
> [Lumen](https://github.com/trollzem/Lumen). It is not an official release of
> either project. See [NOTICE](NOTICE) and [LICENSE](LICENSE).

## Easiest installation — no Xcode or Homebrew

1. Open [Releases](https://github.com/rowizcode/Sunshine-Mac-Cloud-Gaming/releases/latest).
2. Download the file ending in **Apple-Silicon.dmg**.
3. Open the DMG and double-click **Install Sunshine.command**.
4. If macOS blocks it, Control-click the file, choose **Open**, then **Open**
   again.
5. Follow the installer. Allow **Local Network** access, then enable Sunshine
   under **Accessibility** and **Screen & System Audio Recording**.
6. Create the Sunshine Web UI account when
   <https://localhost:47990> opens. The local certificate warning is expected.

The installer backs up an existing Sunshine app, preserves
`~/.config/sunshine`, installs a tested starter configuration only for a new
setup, and enables Sunshine after user login. It never changes SIP, AMFI, NVRAM,
or startup security.

## Connect Moonlight on iPhone or iPad

1. Install **Moonlight Game Streaming** from the App Store.
2. Keep the iPhone/iPad and Mac on the same home network for the first pairing.
3. Open Moonlight and tap the Mac. If it does not appear, add the Mac's local IP
   address manually.
4. Moonlight shows a PIN. On the Mac, sign in to
   <https://localhost:47990>, select **PIN**, and enter it.
5. Open **Desktop** in Moonlight. It shows and controls the physical desktop
   already visible on the Mac, not a separate virtual screen.

Start with these Moonlight settings:

- 1920 × 1080, 60 FPS;
- H.264 and 30–50 Mbps while testing;
- HEVC and 60–70 Mbps after the connection is stable;
- 90/120 FPS only if the physical display, game, and iPhone can all sustain it.

On iOS in trackpad mode: one-finger tap clicks, two-finger drag scrolls, and a
long press followed by a drag performs click-and-drag.

## Optional controller support

Streaming, audio, keyboard, mouse, and touch work without changing startup
security. The virtual controller uses `IOHIDUserDevice` and Apple's restricted
`com.apple.developer.hid.virtual.device` entitlement. An ad-hoc build requires a
one-time AMFI/boot-policy change.

**This weakens macOS security. Do not enable it on a work, banking, or otherwise
security-sensitive Mac. SIP does not need to be disabled.**

Read the complete reversible procedure in
[docs/GAMEPAD.md](docs/GAMEPAD.md). The short Recovery sequence is:

```bash
bputil --disable-boot-args-restriction
nvram boot-args="amfi_get_out_of_my_way=1"
```

After restarting, run the installer once more, connect Moonlight before opening
Steam/the game, and verify the Sunshine log contains `Gamepad 0 allocated`.

Restore the default policy from Recovery with:

```bash
nvram -d boot-args
bputil --full-security
```

## What is included

- ScreenCaptureKit screen and native system-audio capture;
- VideoToolbox hardware H.264/HEVC encoding;
- working macOS click, keyboard, scroll, and Moonlight touch translation;
- Xbox-compatible virtual HID mapping for sticks, triggers, D-pad, A/B/X/Y,
  shoulders, Menu, View, L3, and R3;
- support for multiple Moonlight controller slots via `globalIndex`;
- current physical desktop streaming (`virtual_display = disabled`);
- an auto-start LaunchAgent and a source audit workflow.

The downloadable DMG requires an Apple Silicon Mac running macOS 26 or later.
It is tested on an M4 Mac mini running macOS 26.6 and macOS 27.0 with Moonlight
on iOS and wired Ethernet on the host. Intel Macs are not supported by the
supplied scripts.

## Build from source

People who only want to use the app should download the DMG. Developers can run:

```bash
git clone https://github.com/rowizcode/Sunshine-Mac-Cloud-Gaming.git
cd Sunshine-Mac-Cloud-Gaming
./scripts/build-macos.sh --install-deps
./scripts/package-macos-dmg.sh
```

The source build requires Apple Silicon, Xcode Command Line Tools, and Homebrew.
The generated self-contained DMG appears in `dist/`. The public community DMG is
ad-hoc signed and not Apple-notarized.

## Help

- [Detailed setup](docs/SETUP.md)
- [Gamepad and Recovery-mode security](docs/GAMEPAD.md)
- [Performance tuning](docs/PERFORMANCE.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Architecture and provenance](docs/ARCHITECTURE.md)

Before reporting a problem, run the read-only diagnostic:

```bash
./scripts/diagnose-macos.sh
```

Do not upload `~/.config/sunshine`; it contains credentials, pairing state, TLS
keys, logs, and personal app paths.

## License

GPL-3.0-only. Third-party components retain their own notices and licenses.
