-- Bag mode hotkey for Hammerspoon. Installed by bagmode/install.sh.
-- To change the key, edit ~/.bagmode/config:  BAGMODE_HOTKEY=ctrl,alt,cmd+B
local home = os.getenv("HOME")
local mods, key = { "ctrl", "alt", "cmd" }, "B"

local f = io.open(home .. "/.bagmode/config", "r")
if f then
  for line in f:lines() do
    local m, k = line:match("^BAGMODE_HOTKEY=([%w,]+)%+(%w+)")
    if m then
      mods, key = {}, k
      for part in m:gmatch("[^,]+") do table.insert(mods, part) end
    end
  end
  f:close()
end

bagmodeHotkey = hs.hotkey.bind(mods, key, function()
  hs.task.new(home .. "/.bagmode/bin/bagmode", nil):start()
end)
