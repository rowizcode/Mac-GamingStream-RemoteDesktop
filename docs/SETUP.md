# Setup and permissions

## Requirements

- Apple Silicon Mac
- macOS 14 or later; the tested system is macOS 26.6
- Xcode Command Line Tools: `xcode-select --install`
- Homebrew
- Moonlight on the client

## Build and install

```bash
git clone https://github.com/rowizcode/Sunshine-Mac-Cloud-Gaming.git
cd Sunshine-Mac-Cloud-Gaming
./scripts/build-macos.sh --install-deps
./scripts/install-macos.sh
```

The app uses the same bundle identifier as Sunshine:
`dev.lizardbyte.app.Sunshine`. Replacing the binary can make macOS ask for Screen
Recording or Accessibility again. This is expected.

The installer preserves the complete runtime directory:

```text
~/.config/sunshine/
```

That directory contains pairing state, credentials, TLS keys, logs, and local app
definitions. Back it up privately; never commit it.

## Required permissions

In System Settings → Privacy & Security, enable Sunshine under:

- Screen & System Audio Recording
- Accessibility

If Sunshine is already listed but input still fails, toggle it off and on, quit
Sunshine, and launch it again. Mouse movement can work without Accessibility,
while clicks and keyboard events are blocked; test an actual click.

## Start at login

`install-macos.sh` installs a per-user LaunchAgent by default. Sunshine starts
after the user logs in. macOS does not expose a normal user desktop before login,
so this is not equivalent to unattended control at the FileVault login screen.

Disable automatic startup:

```bash
./scripts/install-macos.sh --no-autostart
```

## Pair Moonlight

1. Launch Sunshine.
2. Open <https://localhost:47990>.
3. Create the Sunshine username and password.
4. Add the Mac in Moonlight or let local discovery find it.
5. Enter Moonlight's PIN in Sunshine.
6. Connect to Desktop.

## Use the current desktop

Keep this in `sunshine.conf`:

```ini
virtual_display = disabled
```

Do not use a prep command that creates or selects a virtual display. If several
physical displays are attached, choose the intended output in Sunshine's web UI.
