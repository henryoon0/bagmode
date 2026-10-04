# bagmode

Keep your Mac awake with the lid closed, for a time you choose. Press a hotkey, pick a time, put the laptop in your bag. Your build, AI agent, or recording keeps running.

Made for people who must move with a laptop (about 1 hour) while work keeps running on it.

> **Heat warning.** A bag has no air flow. Heavy work (builds, local AI models) can make the laptop hot. Bag mode has a maximum of 4 hours and turns off when the battery is below 20%. Do not use it for heavy work in a closed bag.

## Install (1 minute)

Requirements: macOS, an admin account, and [Hammerspoon](https://www.hammerspoon.org) for the hotkey.

Paste this line in Terminal and press Enter:

```bash
curl -fsSL https://raw.githubusercontent.com/henryoon0/bagmode/main/install.sh | bash
```

The installer asks for your **Mac password one time**. macOS lets only an admin change sleep settings. The password adds one rule: your account can run `pmset -a disablesleep 0` and `pmset -a disablesleep 1` without a password. It allows nothing else.

| Your computer | What to do |
| --- | --- |
| macOS (Apple silicon or Intel) | Use the line above |
| Windows | Not supported. Control Panel > Power Options > "Choose what closing the lid does" > "On battery: Do nothing". Set it back after. |
| Linux | Not supported. Run `systemd-inhibit --what=handle-lid-switch:sleep sleep 3600` (1 hour). |

## Use

1. Press **Ctrl + Option + Cmd + B**.
2. Pick a time: 30 min, 1 hour (default, press Enter), 2 hours, or Custom (1–240 min).
3. A popup says "Bag mode on" and shows the time it turns off. Close the lid.

Bag mode turns off by itself when one of these happens. A popup tells you why. If the lid is closed, you see it when you open the lid.

- The time ends
- The battery drops below 20%
- You connect the charger (you arrived)

To turn it off early, press the hotkey again, or click **Turn off now** on the first popup.

If the Mac shuts down while bag mode is on (for example, empty battery), bag mode turns off at the next login.

Popups are in Korean when the macOS language is Korean, and in English otherwise.

## Settings

Edit `~/.bagmode/config`. Remove the `#` from a line to change it.

```bash
BAGMODE_DEFAULT_MIN=60          # time used for "Custom" default
BAGMODE_MAX_MIN=240             # maximum minutes
BAGMODE_MIN_BATTERY=20          # turn off below this battery %
BAGMODE_HOTKEY=ctrl,alt,cmd+B   # hotkey (Hammerspoon key names)
```

After you change the hotkey, reload Hammerspoon (menu bar icon > Reload Config).

## Install with an AI agent

Give this link to Claude Code or Codex and say "install this".

> **For AI agents:**
> 1. Confirm the OS is macOS. On other OS, stop and show the Windows/Linux row of the table above.
> 2. Ask the user to run the install line themselves, in their own terminal (in Claude Code: type `! ` before the command). **You cannot do this step for the user**: it asks for the Mac admin password through `sudo`.
> 3. If Hammerspoon is not installed, tell the user to install it from https://www.hammerspoon.org and run the installer again. Without it there is no hotkey; `~/.bagmode/bin/bagmode` still works from Terminal.
> 4. Verify: run `~/.bagmode/bin/bagmode doctor`. Expect `permission: ok`, `hotkey file: ok`, `login agent: loaded`.
> 5. Test: ask the user to press Ctrl+Option+Cmd+B and pick a time. Then `pmset -g | grep SleepDisabled` shows `1`. Press the hotkey again: it shows `0`.

## Troubleshooting

Run this and paste the result in an issue:

```bash
~/.bagmode/bin/bagmode doctor
```

- **The hotkey does nothing.** Reload Hammerspoon (menu bar icon > Reload Config). If another app uses the same keys, change `BAGMODE_HOTKEY`.
- **"No permission to change sleep settings."** Run the installer again. Your account must be an admin (System Settings > Users & Groups).
- **Company laptop.** IT policy can block admin rights or Hammerspoon. Ask your IT team.

## Why it works this way

macOS always sleeps when you close the lid on battery. `caffeinate` and apps like it cannot stop this. The only switch is `pmset disablesleep`, which needs admin rights and stays on even after a restart. So bagmode adds a narrow permission rule, always turns the switch off on a timer, and checks it again at each login.

## Notes

- Files: `~/.bagmode/` (script, config), `~/.hammerspoon/bagmode.lua` and one `require("bagmode")` line in `~/.hammerspoon/init.lua`, `~/Library/LaunchAgents/io.github.bagmode.login-check.plist`, `/etc/sudoers.d/bagmode`.
- Running the installer again is safe. It does not add duplicate lines.
- Tested on macOS 26.4 (Apple silicon). Other macOS versions and Intel Macs are tested only for install and uninstall in GitHub Actions.

## Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/henryoon0/bagmode/main/uninstall.sh | bash
```

This turns lid-close sleep back on and removes all files above. It asks for your Mac password to remove the permission rule. It does not remove Hammerspoon or your other Hammerspoon settings.

## Files

| File | What it does |
| --- | --- |
| `install.sh` | Installs everything above |
| `uninstall.sh` | Removes everything above |
| `bin/bagmode` | Bag mode: popups, timer, battery and charger checks |
| `hammerspoon/bagmode.lua` | The hotkey |

## License

MIT
