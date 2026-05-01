-- ~/.config/hypr/hyprland.lua
-- Main entry point — sources all module files
-- Each require() is a separate Lua scope, so errors in one won't break others

local modules_dir = "~/.config/hypr/modules/"

require(modules_dir .. "monitors")
require(modules_dir .. "programs")
require(modules_dir .. "env")
require(modules_dir .. "autostart")
require(modules_dir .. "decoration")
require(modules_dir .. "animation")
require(modules_dir .. "windowrules")
require(modules_dir .. "layout")
require(modules_dir .. "misc")
require(modules_dir .. "input")
require(modules_dir .. "binds")
require(modules_dir .. "active")  -- active theme (symlink → themes/xxx.lua)
