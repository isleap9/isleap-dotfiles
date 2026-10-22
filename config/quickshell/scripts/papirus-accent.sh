#!/bin/sh
# papirus-accent.sh FRONT BACK SYMBOL
# Builds ~/.local/share/icons/Papirus-Accent: Papirus-Dark with the folder icons recolored
# (Papirus's blue folders, with their three blues swapped for the given colors).
# Everything else is inherited from Papirus-Dark. Run by the shell when the theme accent changes.
front=$1; back=$2; symbol=$3
src=/usr/share/icons/Papirus
out="$HOME/.local/share/icons/Papirus-Accent"
stamp="$out/.accent"
[ -n "$front" ] && [ -d "$src" ] || exit 1
[ "$(cat "$stamp" 2>/dev/null)" = "$front $back $symbol" ] && exit 0

tmp="$out.tmp.$$"
rm -rf "$tmp"
mkdir -p "$tmp"
dirs=""
for d in "$src"/*/places; do
    rel=${d#"$src"/}
    mkdir -p "$tmp/$rel"
    for f in "$d"/folder-blue.svg "$d"/folder-blue-*.svg "$d"/user-blue-*.svg; do
        [ -e "$f" ] || continue
        name=$(basename "$f")
        # folder-blue-download.svg → folder-download.svg, user-blue-home.svg → user-home.svg
        new=$(echo "$name" | sed 's/^folder-blue/folder/; s/^user-blue-/user-/')
        sed -e "s/#5294e2/$front/gI" -e "s/#4877b1/$back/gI" -e "s/#1d344f/$symbol/gI" "$f" > "$tmp/$rel/$new"
    done
    dirs="$dirs${dirs:+,}$rel"
done

# index.theme: our places folders (sizes copied from Papirus), then Papirus-Dark for the rest
{
    printf '[Icon Theme]\nName=Papirus-Accent\nComment=Papirus-Dark with folders in your theme accent\n'
    printf 'Inherits=Papirus-Dark,breeze-dark,hicolor\nExample=folder\nFollowsColorScheme=true\n'
    printf 'Directories=%s\n\n' "$(echo "$dirs" | tr ',' '\n' | grep -v '@' | paste -sd,)"
    printf 'ScaledDirectories=%s\n\n' "$(echo "$dirs" | tr ',' '\n' | grep '@' | paste -sd,)"
    for rel in $(echo "$dirs" | tr ',' ' '); do
        awk -v sec="[$rel]" '$0 == sec {p = 1; print; next} /^\[/ {p = 0} p' "$src/index.theme"
        echo
    done
} > "$tmp/index.theme"
echo "$front $back $symbol" > "$tmp/.accent"

rm -rf "$out"
mv "$tmp" "$out"
