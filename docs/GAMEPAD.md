# Optional virtual gamepad setup

## Read this warning first

Moonlight sends controller packets to Sunshine. This project turns them into a
system-wide virtual Xbox-compatible controller using `IOHIDUserDevice`. Apple
restricts this capability with the `com.apple.developer.hid.virtual.device`
entitlement. An ordinary ad-hoc community build cannot use that entitlement on
a Mac with the default boot policy.

The workaround below disables boot-argument filtering and AMFI enforcement for
the selected macOS installation. **It makes the Mac easier to compromise. Do not
use it on a work, banking, production, or security-sensitive Mac.** Keyboard,
mouse, touch, video, and audio do not need this change.

SIP does **not** need to be disabled. Back up important data before changing a
startup policy.

## Apple Silicon Recovery steps

1. Shut down the Mac completely.
2. Press and hold the power button until **Loading startup options** appears.
3. Select **Options → Continue** and authenticate when requested.
4. From the Recovery menu bar choose **Utilities → Terminal**.
5. Run:

   ```bash
   bputil --disable-boot-args-restriction
   ```

   Follow the volume/account/password prompts. `bputil` warns that this selects
   Permissive Security and weakens the system.

6. Run:

   ```bash
   nvram boot-args="amfi_get_out_of_my_way=1"
   ```

7. Restart normally.
8. Run `Install Sunshine.command` again. It signs the copied app with the HID
   entitlements but does not alter NVRAM itself.

If the Mac already contains another required boot argument, do not overwrite it
blindly. Record the current value with `nvram boot-args` and obtain expert help
to merge it safely.

## Verify and use the controller

The installer reports whether the running kernel has the AMFI boot argument.
For a detailed read-only test, run:

```bash
./scripts/diagnose-macos.sh
```

Successful log lines are:

```text
macOS Accessibility permission is active
IOHIDUserDevice virtual gamepad support is available
Gamepad 0 allocated (IOHIDUserDevice mode)
```

Use this sequence for Steam and games that cache controller devices:

1. Fully quit the game and Steam.
2. Disconnect Moonlight.
3. Reconnect Moonlight with a physical or on-screen controller enabled.
4. Confirm `Gamepad 0 allocated` in Sunshine's log.
5. Start Steam and the game.

The mapping provides both sticks, analog triggers, an eight-way D-pad, Xbox
A/B/X/Y, shoulders, Menu, View, L3, and R3. Controller touchpads and motion
sensors are not exposed. Touching the iPhone screen uses Moonlight's mouse/touch
path, not the controller touchpad path.

## Restore normal security

Return to Recovery using the same power-button procedure and run:

```bash
nvram -d boot-args
bputil --full-security
```

Restart normally. The virtual controller will no longer work, while video,
audio, keyboard, mouse, and touch continue to work.

The `nvram -d boot-args` command removes **all** boot arguments. If the Mac had
other required boot arguments before this project, restore the recorded value
instead of deleting it.
