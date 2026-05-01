-- https://wiki.hypr.land/Configuring/Animations/

hl.config({
    animations = {
        enabled = true,

        beziers = {
            easeOutQuint   = { 0.23, 1,    0.32, 1    },
            easeInOutCubic = { 0.65, 0.05, 0.36, 1    },
            linear         = { 0,    0,    1,    1    },
            almostLinear   = { 0.5,  0.5,  0.75, 1    },
            quick          = { 0.15, 0,    0.1,  1    },
        },

        animations = {
            { name = "global",        enabled = true, speed = 10,   curve = "default"       },
            { name = "border",        enabled = true, speed = 5.39, curve = "easeOutQuint"  },

            { name = "windows",       enabled = true, speed = 4.79, curve = "easeOutQuint",  style = "slide"      },
            { name = "windowsIn",     enabled = true, speed = 4.1,  curve = "easeOutQuint",  style = "slide"      },
            { name = "windowsOut",    enabled = true, speed = 1.49, curve = "linear",         style = "slide"      },

            { name = "fadeIn",        enabled = true, speed = 1.73, curve = "almostLinear"  },
            { name = "fadeOut",       enabled = true, speed = 1.46, curve = "almostLinear"  },
            { name = "fade",          enabled = true, speed = 3.03, curve = "quick"         },

            { name = "layers",        enabled = true, speed = 3.81, curve = "easeOutQuint",  style = "popin"      },
            { name = "layersIn",      enabled = true, speed = 4,    curve = "easeOutQuint",  style = "popin 90%"  },
            { name = "layersOut",     enabled = true, speed = 1.5,  curve = "linear",         style = "popin 90%"  },

            { name = "fadeLayersIn",  enabled = true, speed = 1.79, curve = "almostLinear"  },
            { name = "fadeLayersOut", enabled = true, speed = 1.39, curve = "almostLinear"  },

            { name = "workspaces",    enabled = true, speed = 1.94, curve = "almostLinear",  style = "fade"       },
            { name = "workspacesIn",  enabled = true, speed = 1.21, curve = "almostLinear",  style = "fade"       },
            { name = "workspacesOut", enabled = true, speed = 1.94, curve = "almostLinear",  style = "fade"       },

            { name = "zoomFactor",    enabled = true, speed = 7,    curve = "quick"         },
        },
    },
})
