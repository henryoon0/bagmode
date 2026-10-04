#!/bin/bash
# Remove bag mode and turn lid-close sleep back on.
set -euo pipefail

main() {
  local DIR="$HOME/.bagmode" HS="$HOME/.hammerspoon"
  local LABEL="io.github.bagmode.login-check"
  [ "$(uname -s)" = "Darwin" ] || { echo "Bag mode is for macOS only. Nothing to remove."; exit 0; }

  [ -x "$DIR/bin/bagmode" ] && [ "$("$DIR/bin/bagmode" status)" = on ] && pkill -f "bagmode __watch" || true
  sudo -n /usr/bin/pmset -a disablesleep 0 2>/dev/null || true

  launchctl bootout "gui/$(id -u)/$LABEL" 2>/dev/null || true
  rm -f "$HOME/Library/LaunchAgents/$LABEL.plist"

  if [ -f "$HS/init.lua" ]; then
    local tmp; tmp="$(mktemp)"
    grep -vF -e '-- bagmode (added by bagmode/install.sh)' -e 'require("bagmode")' "$HS/init.lua" > "$tmp" || true
    cat "$tmp" > "$HS/init.lua"; rm -f "$tmp"
    # The installer may have created init.lua; remove it if nothing else is left.
    if ! grep -q '[^[:space:]]' "$HS/init.lua"; then rm -f "$HS/init.lua"; rmdir "$HS" 2>/dev/null || true; fi
  fi
  rm -f "$HS/bagmode.lua"
  rm -rf "$DIR"

  if [ -f /etc/sudoers.d/bagmode ]; then
    echo "Removing the permission rule needs your Mac password."
    sudo rm -f /etc/sudoers.d/bagmode </dev/tty 2>/dev/null || sudo rm -f /etc/sudoers.d/bagmode \
      || echo "Could not remove /etc/sudoers.d/bagmode. Run: sudo rm /etc/sudoers.d/bagmode"
  fi
  echo "Bag mode removed."
}

main "$@"
