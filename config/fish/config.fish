if status is-interactive
    # Commands to run in interactive sessions can go here
end

set fish_greeting
starship init fish | source
fastfetch

# Default editor
set -gx EDITOR micro
set -gx VISUAL micro
