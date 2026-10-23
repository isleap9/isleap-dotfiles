-------------------
--- KEYBINDINGS ---
-------------------

local mainMod = "SUPER"

-- Apps
hl.bind(mainMod .. " + T",           hl.dsp.exec_cmd("kitty"))                                          -- terminal
hl.bind(mainMod .. " + Q",           hl.dsp.window.close())                                             -- kill active
hl.bind(mainMod .. " + B",           hl.dsp.exec_cmd("google-chrome-stable"))                           -- browser
hl.bind(mainMod .. " + C",           hl.dsp.exec_cmd("code"))                                           -- vscode
hl.bind(mainMod .. " + P",           hl.dsp.exec_cmd("qs ipc call powermenu toggle"))       -- power menu
hl.bind(mainMod .. " + ALT + E",           hl.dsp.exec_cmd("dolphin"))                                        -- file manager
hl.bind(mainMod .. " + E",           hl.dsp.exec_cmd("qs ipc call files launch"))                      -- Quickshell Files (new window each press)
hl.bind(mainMod .. " + SPACE",       hl.dsp.exec_cmd("qs ipc call launcher toggle"))                                -- app launcher ($menu)
hl.bind(mainMod .. " + A",           hl.dsp.exec_cmd("qs ipc call dashboard toggle"))                   -- dashboard
hl.bind(mainMod .. " + X",           hl.dsp.exec_cmd("qs ipc call quicksettings toggle"))               -- quick settings
hl.bind(mainMod .. " + TAB",         hl.dsp.exec_cmd("qs ipc call overview toggle"))                    -- workspace overview
hl.bind(mainMod .. " + R",           hl.dsp.exec_cmd("~/.config/quickshell/scripts/launch.sh"))         -- quickshell reload
hl.bind(mainMod .. " + D",           hl.dsp.exec_cmd("discord"))								-- discord
hl.bind(mainMod .. " + M",			 hl.dsp.exec_cmd("spotify"))								-- spotify

-- Window management
hl.bind(mainMod .. " + W",           hl.dsp.window.float({ action = "toggle" }))                        -- toggle floating
hl.bind(mainMod .. " + F",           hl.dsp.window.fullscreen({ mode = 1 }))                   -- maximize
hl.bind(mainMod .. " + SHIFT + F",   hl.dsp.window.fullscreen({ mode = 0 }))                 -- true fullscreen

-- Move focus (j/l/i/k = left/right/up/down)
hl.bind(mainMod .. " + j",           hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + l",           hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + i",           hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + k",           hl.dsp.focus({ direction = "down" }))

-- Switch workspaces (SUPER + 1-9, 0 = ws 10)
for i = 1, 9 do
    hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
end
hl.bind(mainMod .. " + 0",           hl.dsp.focus({ workspace = "10" }))

-- Move active window to workspace (SUPER + SHIFT + 1-9, 0 = ws 10)
for i = 1, 9 do
    hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end
hl.bind(mainMod .. " + SHIFT + 0",   hl.dsp.window.move({ workspace = "10" }))

-- Special workspace (scratchpad)
hl.bind(mainMod .. " + S",           hl.dsp.workspace.toggle_special("magic"))

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
hl.bind("XF86MonBrightnessUp",       hl.dsp.exec_cmd("qs ipc call brightness raise"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown",     hl.dsp.exec_cmd("qs ipc call brightness lower"), { repeating = true, locked = true })

-- Media (works on lockscreen)
hl.bind("XF86AudioNext",             hl.dsp.exec_cmd("playerctl next"),        { locked = true })
hl.bind("XF86AudioPause",            hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPlay",             hl.dsp.exec_cmd("playerctl play-pause"),  { locked = true })
hl.bind("XF86AudioPrev",             hl.dsp.exec_cmd("playerctl previous"),    { locked = true })

-- Notifications (quickshell)
hl.bind(mainMod .. " + N",           hl.dsp.exec_cmd("qs ipc call notifications toggle"))

-- Clipboard
hl.bind(mainMod .. " + SHIFT + C",   hl.dsp.exec_cmd("qs ipc call controlcenter open clipboard"))

-- Screenshots
hl.bind(mainMod .. " + SHIFT + S",   hl.dsp.exec_cmd("hyprshot -m region --output-folder ~/Pictures/Screenshots"))

-- Capture
hl.bind(mainMod .. " + SHIFT + V",   hl.dsp.exec_cmd("qs ipc call controlcenter open capture"))

-- Wallpaper selector
hl.bind(mainMod .. " + SHIFT + W",   hl.dsp.exec_cmd("~/.config/quickshell/scripts/wallpaper-picker.sh"))

-- Theme switcher
hl.bind(mainMod .. " + SHIFT + T",   hl.dsp.exec_cmd("qs ipc call controlcenter open themes"))

-- Control center
hl.bind(mainMod .. " + ALT + SPACE",   hl.dsp.exec_cmd("qs ipc call controlcenter toggle"))

-- Lock screen
hl.bind(mainMod .. " + SHIFT + L",   hl.dsp.exec_cmd("loginctl lock-session"))   -- locks with qylock (via hypridle)

-- Color picker
hl.bind(mainMod .. " + SHIFT + P",   hl.dsp.exec_cmd("~/.config/hypr/scripts/color-picker.sh"))

-- Emoji picker (quickshell control center)
hl.bind(mainMod .. " + PERIOD",      hl.dsp.exec_cmd("qs ipc call controlcenter open emoji"))

-- Quickshell settings app
hl.bind(mainMod .. " + COMMA",       hl.dsp.exec_cmd("qs ipc call settings toggle"))
