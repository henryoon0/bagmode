#!/bin/bash
# Install bag mode: keep a Mac awake with the lid closed, with a hotkey.
#   curl -fsSL https://raw.githubusercontent.com/henryoon0/bagmode/main/install.sh | bash
set -euo pipefail

main() {
  local REPO_RAW="${BAGMODE_RAW:-https://raw.githubusercontent.com/henryoon0/bagmode/main}"
  local DIR="$HOME/.bagmode" HS="$HOME/.hammerspoon"
  local LABEL="io.github.bagmode.login-check"
  local PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
  local SUDOERS="/etc/sudoers.d/bagmode"
  local MARK="-- bagmode (added by bagmode/install.sh)"

  if [ "$(uname -s)" != "Darwin" ]; then
    cat <<'MSG'
Bag mode is for macOS only. Nothing was changed.

To keep a laptop awake with the lid closed:
  Windows: Control Panel > Power Options > "Choose what closing the lid does"
           > set "On battery" to "Do nothing". Set it back when you are done.
  Linux:   systemd-inhibit --what=handle-lid-switch:sleep sleep 3600
           (keeps the laptop awake for 1 hour, then stops)
MSG
    exit 1
  fi

  # Use files next to this script when run from a clone. Download them otherwise.
  local SRC=""
  if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    [ -f "$SRC/bin/bagmode" ] && [ -f "$SRC/hammerspoon/bagmode.lua" ] || SRC=""
  fi
  fetch() { # repo path, destination
    if [ -n "$SRC" ]; then cp "$SRC/$1" "$2"; else curl -fsSL "$REPO_RAW/$1" -o "$2"; fi
  }

  echo "==> Installing bag mode"
  mkdir -p "$DIR/bin" "$HOME/Library/LaunchAgents"
  fetch bin/bagmode "$DIR/bin/bagmode.new"
  chmod +x "$DIR/bin/bagmode.new"
  mv "$DIR/bin/bagmode.new" "$DIR/bin/bagmode"
  [ -f "$DIR/config" ] || cat > "$DIR/config" <<'CONF'
# Bag mode settings. Remove the "#" to change a value.
# BAGMODE_DEFAULT_MIN=60
# BAGMODE_MAX_MIN=240
# BAGMODE_MIN_BATTERY=20
# BAGMODE_HOTKEY=ctrl,alt,cmd+B
CONF

  # Reset a mode left on after a crash or reboot, at each login.
  cat > "$PLIST" <<PL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key><array><string>$DIR/bin/bagmode</string><string>login-check</string></array>
  <key>RunAtLoad</key><true/>
</dict></plist>
PL
  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  launchctl bootstrap "gui/$(id -u)" "$PLIST" 2>/dev/null || true

  # Hotkey (Hammerspoon). Add one require line; do not touch the rest of init.lua.
  local hs_ok=0
  if [ -d /Applications/Hammerspoon.app ] || [ -d "$HOME/Applications/Hammerspoon.app" ]; then
    hs_ok=1
    mkdir -p "$HS"
    fetch hammerspoon/bagmode.lua "$HS/bagmode.lua"
    touch "$HS/init.lua"
    if ! grep -qF 'require("bagmode")' "$HS/init.lua"; then
      printf '\n%s\nrequire("bagmode")\n' "$MARK" >> "$HS/init.lua"
    fi
    if pgrep -xq Hammerspoon; then
      osascript -e 'tell application "Hammerspoon" to execute lua code "hs.reload()"' >/dev/null 2>&1 \
        || echo "    Reload Hammerspoon config: menu bar icon > Reload Config"
    fi
  fi

  # Permission: let this user run only "pmset -a disablesleep 0|1" without a password.
  local me rule tmp
  me="$(id -un)"
  rule="$me ALL=(root) NOPASSWD: /usr/bin/pmset -a disablesleep 0, /usr/bin/pmset -a disablesleep 1"
  if sudo -n -l /usr/bin/pmset -a disablesleep 1 >/dev/null 2>&1; then
    echo "==> Permission already set"
  else
    tmp="$(mktemp)"
    echo "$rule" > "$tmp"
    if ! /usr/sbin/visudo -cf "$tmp" >/dev/null; then
      rm -f "$tmp"; echo "Error: permission rule check failed. Nothing was added." >&2; exit 1
    fi
    echo
    echo "==> One step needs your Mac password (admin)."
    echo "    It allows only one command: turning lid-close sleep off/on."
    if sudo install -m 440 -o root -g wheel "$tmp" "$SUDOERS" </dev/tty 2>/dev/null \
       || sudo install -m 440 -o root -g wheel "$tmp" "$SUDOERS"; then
      echo "==> Permission set"
    else
      rm -f "$tmp"
      echo
      echo "Could not set the permission. Your account may not be an admin"
      echo "(System Settings > Users & Groups). Run the installer again as an admin."
      exit 1
    fi
    rm -f "$tmp"
  fi

  echo
  echo "Done."
  if [ "$hs_ok" = 1 ]; then
    echo "  Press Ctrl+Option+Cmd+B, pick a time, then close the lid."
  else
    echo "  Hammerspoon is not installed, so there is no hotkey."
    echo "  Install it from https://www.hammerspoon.org, then run this installer again."
    echo "  Until then, run: ~/.bagmode/bin/bagmode"
  fi
  echo "  Change time limits or the hotkey in ~/.bagmode/config"
}

main "$@"
