#####################
--- LOOK AND FEEL ---
#####################

hl.config({
    general = {
        gaps_in  = 8,
        gaps_out = 30,

        border_size = 2,

        resize_on_border = true,
        allow_tearing    = false,

        layout = "dwindle",
    },

    decoration = {
        rounding       = 10,
        rounding_power = 2,

        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 15,
            render_power = 3,
            color        = "rgba(0a0a0add)",
        },

        blur = {
            enabled          = true,
            size             = 7,
            passes           = 3,
            new_optimizations = true,
            vibrancy         = 0.1696,
            xray             = false,
        },
    },
})
