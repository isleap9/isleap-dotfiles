-------------
--- INPUT ---
-------------

hl.config({
    input = {
        kb_layout  = "gb,it",
        kb_variant = "",
        kb_model   = "",
        kb_options = "grp:alt_shift_toggle",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity   = 0,
        accel_profile = "flat",
        force_no_accel = true,

        touchpad = {
            natural_scroll = false,
        },
    },
})

-- 3-finger horizontal swipe to switch workspace
hl.gesture({ fingers = 3, direction = "horizontal", dispatcher = hl.dsp.focus({ workspace = "e+1" }) })

-- Per-device config
hl.device({
    name        = "epic-mouse-v1",
    sensitivity = -0.5,
})
