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

-- Layer rules
hl.layer_rule({ match = { namespace = "swaync-control-center"    }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "swaync-notification-window" }, blur = true, ignore_alpha = 0.5 })
hl.layer_rule({ match = { namespace = "logout_dialog"            }, blur = true, ignore_alpha = 0.0 })
hl.layer_rule({ match = { namespace = "rofi"                     }, blur = true, ignore_alpha = 0.1 })
