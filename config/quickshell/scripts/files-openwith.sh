#!/bin/sh
# files-openwith.sh FILE — for the Files "Open with…" dialog. Prints:
#   line 1: the file's mime type
#   line 2: the default app (desktop id)
#   then:   desktop ids of apps that can open it (may repeat)
f=$1
mime=$(xdg-mime query filetype "$f" 2>/dev/null)
[ -n "$mime" ] || mime=$(file -b --mime-type -- "$f")
echo "$mime"
xdg-mime query default "$mime" 2>/dev/null || echo
dirs="$HOME/.local/share/applications /usr/local/share/applications /usr/share/applications
/var/lib/flatpak/exports/share/applications $HOME/.local/share/flatpak/exports/share/applications"
types=$mime
case $mime in text/*) [ "$mime" != text/plain ] && types="$mime text/plain" ;; esac
for t in $types; do
    for d in $dirs; do
        [ -f "$d/mimeinfo.cache" ] && grep -h "^$t=" "$d/mimeinfo.cache" | cut -d= -f2 | tr ';' '\n'
        # Desktop files newer than the cache
        [ -d "$d" ] && grep -l "^MimeType=.*$t;" "$d"/*.desktop 2>/dev/null | xargs -r -n1 basename
    done
    for l in "$HOME/.config/mimeapps.list" "$HOME/.local/share/applications/mimeapps.list"; do
        [ -f "$l" ] && sed -n '/^\[Added Associations\]/,/^\[/p' "$l" | grep "^$t=" | cut -d= -f2 | tr ';' '\n'
    done
done | grep -v '^$'
