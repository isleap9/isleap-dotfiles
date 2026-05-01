-------------------
--- KEYBINDINGS ---
-------------------

local mainMod = "SUPER"

-- Apps
hl.bind(mainMod .. " + T",           hl.dsp.exec_cmd("kitty"))                                          -- terminal
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())                                             -- kill active
hl.bind(mainMod .. " + B",           hl.dsp.exec_cmd("google-chrome-stable"))                           -- browser
hl.bind(mainMod .. " + C",           hl.dsp.exec_cmd("code"))                                           -- vscode
hl.bind(mainMod .. " + M",           hl.dsp.exec_cmd("bash ~/.config/rofi/scripts/powermenu.sh"))       -- power menu
hl.bind(mainMod .. " + E",           hl.dsp.exec_cmd("dolphin"))                                        -- file manager
hl.bind(mainMod .. " + A",           hl.dsp.exec_cmd("rofi -show drun"))                                -- app launcher ($menu)
hl.bind(mainMod .. " + R",           hl.dsp.exec_cmd("~/.config/waybar/scripts/launch.sh"))             -- waybar reload

-- Window management
hl.bind(mainMod .. " + W",           hl.dsp.window.float({ action = "toggle" }))                        -- toggle floating
hl.bind(mainMod .. " + P",           hl.dsp.window.pseudo())                                            -- pseudo (dwindle)
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen({ mode = "maximize" }))                   -- maximize
hl.bind(mainMod .. " + SHIFT + F",   hl.dsp.window.fullscreen({ mode = "fullscreen" }))                 -- true fullscreen
hl.bind(mainMod .. " + SHIFT + J",   hl.dsp.layout("togglesplit"))                                      -- toggle split (dwindle)

-- Move focus (j/l/i/k = left/right/up/down)
hl.bind(mainMod .. " + j",           hl.dsp.focus({ direction = "l" }))
hl.bind(mainMod .. " + l",           hl.dsp.focus({ direction = "r" }))
hl.bind(mainMod .. " + i",           hl.dsp.focus({ direction = "u" }))
hl.bind(mainMod .. " + k",           hl.dsp.focus({ direction = "d" }))

-- Switch workspaces (SUPER + 1-9, 0 = ws 10)
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
end
hl.bind(mainMod .. " + 0",           hl.dsp.focus({ workspace = "10" }))

-- Move active window to workspace (SUPER + SHIFT + 1-9, 0 = ws 10)
for i = 1, 9 do
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move_to_workspace({ workspace = tostring(i) }))
end
hl.bind(mainMod .. " + SHIFT + 0",   hl.dsp.window.move_to_workspace({ workspace = "10" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",           hl.dsp.special_workspace({ name = "magic" }))

-- Scroll through workspaces with SUPER + mouse wheel
hl.bind(mainMod .. " + mouse_down",  hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",    hl.dsp.focus({ workspace = "e-1" }))

-- Move/resize windows with SUPER + LMB/RMB drag
hl.bind(mainMod .. " + mouse:272",   hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273",   hl.dsp.window.resize(), { mouse = true })

-- Volume (repeating + works on lockscreen)
hl.bind("XF86AudioRaiseVolume",      hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),  { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume",      hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),       { repeating = true, locked = true })
hl.bind("XF86AudioMute",             hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),      { locked = true })
hl.bind("XF86AudioMicMute",          hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),    { locked = true })

-- Brightness (repeating + works on lockscreen)
hl.bind("XF86MonBrightnessUp",       hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown",     hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"), { repeating = true, locked = true })

-- Media (works on lockscreen)
hl.bind("XF86AudioNext",             hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPause",            hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPlay",             hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPrev",             hl.dsp.exec_cmd("playerctl previous"),    { locked = true })

-- Notifications (swaync)
hl.bind(mainMod .. " + N",           hl.dsp.exec_cmd("swaync-client -t"))

-- Clipboard
hl.bind(mainMod .. " + SHIFT + C",   hl.dsp.exec_cmd("bash ~/.config/rofi/scripts/clipboard.sh"))

-- Screenshots
hl.bind(mainMod .. " + SHIFT + S",   hl.dsp.exec_cmd("hyprshot -m region --output-folder /home/isleap/Pictures/Screenshots"))

-- Capture
hl.bind(mainMod .. " + SHIFT + V",   hl.dsp.exec_cmd("bash ~/.config/rofi/scripts/capture.sh"))

-- Wallpaper selector
hl.bind(mainMod .. " + SHIFT + W",   hl.dsp.exec_cmd("~/.config/rofi/scripts/wallpaper-picker.sh"))

-- Theme switcher
hl.bind(mainMod .. " + SHIFT + T",   hl.dsp.exec_cmd("~/.config/waybar/scripts/theme-switcher.sh"))

-- Control center
hl.bind(mainMod .. " + SHIFT + E",   hl.dsp.exec_cmd("bash ~/.config/rofi/scripts/control-center.sh"))

-- Lock screen
hl.bind(mainMod .. " + L",           hl.dsp.exec_cmd("blazinlock -s"))

-- Color picker
hl.bind(mainMod .. " + SHIFT + P",   hl.dsp.exec_cmd("~/.config/hypr/scripts/color-picker.sh"))
