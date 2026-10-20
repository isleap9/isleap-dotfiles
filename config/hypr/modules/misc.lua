hl.config({
    misc = {
        force_default_wallpaper = -1,
        disable_hyprland_logo   = false,

        -- Any mouse movement or key press turns the screens back on after they've been switched off
        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,

        -- If the lock screen ever crashes, let it be restarted instead of leaving a dead locked screen
        allow_session_lock_restore = true,
    },
})
