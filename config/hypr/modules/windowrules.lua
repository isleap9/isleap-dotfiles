------------------------------
--- WINDOWS AND WORKSPACES ---
------------------------------

-- Ignore maximize requests from all apps
hl.window_rule({
    name            = "suppress-maximize-events",
    match           = { class = ".*" },
    suppress_event  = "maximize",
})

-- Fix some dragging issues with XWayland
hl.window_rule({
    name       = "fix-xwayland-drags",
    match      = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },
    no_focus   = true,
})

-- hyprland-run float at bottom of screen
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },
    move  = { 20, "monitor_h-120" },
    float = true,
})

-- hyprpicker always float, no anim
hl.window_rule({ match = { class = "hyprpicker" }, float   = true })
hl.window_rule({ match = { class = "hyprpicker" }, no_anim = true })

-- Layer rules: frosted blur behind the Quickshell bar and its panels (they follow the bar's opacity)
for _, ns in ipairs({ "quickshell-bar", "quickshell-dashboard", "quickshell-quicksettings",
                      "quickshell-traymenu", "quickshell-hovercard", "quickshell-osd", "quickshell-overview", "quickshell-polkit" }) do
    -- xray: blur only the wallpaper (not windows), so panels over windows match the bar over the wallpaper
    hl.layer_rule({ match = { namespace = ns }, blur = true, blur_popups = true, xray = true, ignore_alpha = 0.3 })
end



-- arch-update: open on focused monitor
hl.window_rule({ match = { class = "kitty", title = ".*arch-update.*" }, monitor = "current" })

-- Quickshell
hl.layer_rule({ match = { namespace = "quickshell-notification-center" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "quickshell-launcher" }, blur = true, ignore_alpha = 0.5 })

-- qs-wallpaper-picker: float centered
hl.window_rule({
    name   = "wallpaper-picker",
    match  = { title = "^wallpaper-picker$" },
    float  = true,
    center = true,
})
hl.layer_rule({ match = { namespace = "quickshell-control-center" }, blur = true, ignore_alpha = 0.5 })

-- Quickshell Settings window: float centered
hl.window_rule({
    name   = "quickshell-settings",
    match  = { title = "^Quickshell Settings$" },
    float  = true,
    center = true,
})

-- Arch-Update (kitty window opened from the tray / notification): float centered
hl.window_rule({
    name   = "arch-update",
    match  = { class = "^arch-update$" },
    float  = true,
    center = true,
    size   = { 1100, 700 },
})
