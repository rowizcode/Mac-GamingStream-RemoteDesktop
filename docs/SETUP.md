# Easy setup with Moonlight

## What you need

- an Apple Silicon Mac (M1/M2/M3/M4/M5 family);
- macOS 26 or later for the downloadable DMG;
- an iPhone or iPad with Moonlight Game Streaming;
- both devices on the same home network for first pairing;
- a logged-in Mac user session. Sunshine cannot control the FileVault pre-login
  screen after a restart.

## Install the DMG

1. Download the latest `Apple-Silicon.dmg` from the GitHub Releases page.
2. Open it and double-click `Install Sunshine.command`.
3. If Gatekeeper blocks it, Control-click the installer and choose **Open**.
4. The guided installer:
   - selects `/Applications` when writable, otherwise `~/Applications`;
   - backs up an existing Sunshine app with a timestamp;
   - preserves all existing credentials, pairing state, certificates, and app
     definitions in `~/.config/sunshine`;
   - installs the recommended config only when no config exists;
   - enables Sunshine after user login;
   - opens the required macOS permission pages.

Turn Sunshine on under:

1. **Privacy & Security → Accessibility**
2. **Privacy & Security → Screen & System Audio Recording**
3. **Privacy & Security → Local Network** (macOS 15 and later)

The installer restarts Sunshine after the permissions are selected. Mouse
movement may work without Accessibility, but clicks and keyboard events will
not.

## Create the Web UI account

The browser opens <https://localhost:47990>. A certificate warning is normal
because Sunshine generates its own local certificate. Continue only when the
address is exactly `localhost:47990`.

Create a username and a strong password. This is a new Sunshine account, not
the Mac login account and not an Apple ID. The account protects pairing and
configuration access.

## Pair Moonlight

1. Open Moonlight on the iPhone/iPad.
2. Tap the Mac. If discovery fails, add the Mac's local IP address manually.
3. Moonlight displays a PIN.
4. On the Mac, sign in to the Sunshine Web UI, choose **PIN**, enter the number,
   and submit it.
5. Choose **Desktop** in Moonlight.

iOS/tvOS requires the first pairing on the same network. After pairing, remote
access can be added later with a private VPN such as Tailscale; do not expose the
Sunshine Web UI directly to the public Internet.

## Recommended first test

Use 1920×1080, 60 FPS, H.264, and 30–50 Mbps. Check that video, audio, tapping,
clicking, and scrolling work. Then try HEVC or a higher bitrate. A speed test
does not measure local Wi-Fi jitter.

The bundled config keeps `virtual_display = disabled`, so Moonlight controls the
same physical desktop visible on the Mac.

## Controller

The optional virtual controller needs a Recovery-mode security change. Complete
[GAMEPAD.md](GAMEPAD.md) only if a controller is required. Do not disable SIP.

## Build from source instead

```bash
git clone https://github.com/rowizcode/Sunshine-Mac-Cloud-Gaming.git
cd Sunshine-Mac-Cloud-Gaming
./scripts/build-macos.sh --install-deps
./scripts/package-macos-dmg.sh
```
