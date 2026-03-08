-- Add the sketchybar module to the package cpath
package.cpath = package.cpath .. ";" .. os.getenv("HOME") .. "/.local/share/sketchybar_lua/?.so"

local ok = os.execute("make -C " .. os.getenv("HOME") .. "/.config/sketchybar/helpers")
if ok ~= true and ok ~= 0 then
  print("[sketchybar] WARNING: C helper build failed — using existing binaries")
end
