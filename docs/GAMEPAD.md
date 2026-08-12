# Virtual gamepad and macOS security

## Why this is different from mouse input

Moonlight sends controller packets to Sunshine. On macOS, this project translates
them into a virtual Xbox-compatible HID device with `IOHIDUserDevice`. Apple
documents `com.apple.developer.hid.virtual.device` as the entitlement that allows
an app to create and manage virtual HID devices. It is restricted; an ordinary
ad-hoc signed app cannot use it on a default-secured Mac.

The tested build uses these entitlements:

```text
com.apple.developer.hid.virtual.device
com.apple.private.hid.client.event-dispatch
```

## Security decision

The Lumen project documents using this boot argument for its virtual gamepad:

```text
amfi_get_out_of_my_way=1
```

Setting or removing boot arguments is a security-sensitive Recovery operation.
This repository intentionally does not automate it. Disabling AMFI weakens macOS
code-integrity enforcement; do not do it on a machine where that risk is
unacceptable.

The test Mac also had SIP disabled while this fork was developed. Lumen states
that SIP is not required for its virtual HID backend, so this project does not
instruct users to disable SIP. The project needs more clean-machine validation.

## Verify the local state

Run the read-only diagnostic:

```bash
./scripts/diagnose-macos.sh
```

The relevant successful log lines are:

```text
macOS Accessibility permission is active
IOHIDUserDevice virtual gamepad support is available
Gamepad 0 allocated (IOHIDUserDevice mode)
```

`No gamepad input is available` at startup only means no controller has been
allocated yet. Connect Moonlight with a controller enabled and check the log
again.

## Steam-specific test sequence

1. Fully quit the game.
2. Disconnect the Moonlight session.
3. Reconnect Moonlight with the physical or on-screen controller enabled.
4. Confirm `Gamepad 0 allocated` in the Sunshine log.
5. Start Steam and then the game.

Launching the game before Moonlight creates the HID controller can make some
games cache an empty controller list. Reconnecting is then required.

## Mapping used by this project

- sticks: four unsigned 16-bit HID axes with neutral at `0x8000`;
- triggers: 10-bit HID axes;
- D-pad: eight-way hat switch;
- face buttons: Xbox A/B/X/Y order;
- shoulders, Menu, View, L3, and R3: standard button positions;
- Moonlight controller slots: `globalIndex` is used directly.

Controller touchpads and motion sensors are not exposed by this Xbox-compatible
profile. Touch gestures on the iPhone screen are translated through Moonlight's
mouse/touch path, not the gamepad touchpad path.
