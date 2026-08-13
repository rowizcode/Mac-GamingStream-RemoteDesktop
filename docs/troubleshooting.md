# Troubleshooting

## The Mac disappears from Moonlight after a macOS update

On macOS 15 and later, Sunshine needs Local Network permission for Bonjour
discovery. Open System Settings → Privacy & Security → Local Network and turn
Sunshine on, then quit and reopen Sunshine. The log should contain:

```text
Successfully registered DNS service.
```

If Sunshine is missing from the list, install the latest release from this
repository first. Older builds did not declare the Local Network usage string
required by newer macOS releases. You can still add the Mac's LAN IP manually
in Moonlight while troubleshooting discovery.

## Cursor moves but clicks do not work

Sunshine lacks Accessibility permission. Enable Sunshine in System Settings →
Privacy & Security → Accessibility, restart Sunshine, and look for:

```text
macOS Accessibility permission is active
```

## Video works but the controller does not

Run `./scripts/diagnose-macos.sh`. If the log reports
`IOHIDUserDevice virtual gamepad support is unavailable`, the app is either not
signed with the required entitlements or the Mac security state rejects them.
Read [GAMEPAD.md](GAMEPAD.md); do not change security settings blindly.

If the virtual device is available but Steam sees nothing, reconnect Moonlight
before opening the game and confirm `Gamepad 0 allocated` in the log.

## Only one stick or the buttons are mapped incorrectly

Ensure the installed app came from this repository and that no controller
remapper is translating the same device twice. Fully quit Steam and the game,
reconnect Moonlight, and test Steam's controller input screen first.

## Moonlight receives H.264 although HEVC is selected

Check both ends:

- Sunshine must log `Found HEVC encoder: hevc_videotoolbox`.
- Moonlight must request HEVC for the current connection.

Reconnect after changing codec settings. AV1 is not available on every Apple
Silicon generation.

## High latency on a fast network

Lower Moonlight bitrate temporarily and inspect packet loss/jitter. Match display
refresh rate to the stream and compare H.264 with HEVC. A speed-test result does
not diagnose Wi-Fi airtime or bufferbloat.

## Web UI images are missing

This does not affect the stream. Rebuild with `scripts/build-macos.sh`; the script
copies the generated web assets and app images into the bundle.

## Read logs

```bash
tail -f ~/.config/sunshine/sunshine.log
```

Do not upload the full config directory. It contains credentials, certificates,
pairing state, and potentially personal app paths.
