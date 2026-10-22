#!/bin/sh
# files-paste.sh copy|cut DEST SRC...  — Quickshell file explorer paste.
# Never overwrites: a clash becomes "name (copy).ext", "name (copy 2).ext", …
mode=$1; dest=$2; shift 2
status=0
for src; do
    base=$(basename -- "$src")
    if [ "$mode" = cut ] && [ "$(dirname -- "$src")" = "$dest" ]; then continue; fi
    case $base in
        ?*.*) stem=${base%.*}; ext=.${base##*.} ;;
        *) stem=$base; ext= ;;
    esac
    name=$base; n=1
    while [ -e "$dest/$name" ] || [ -L "$dest/$name" ]; do
        if [ $n -eq 1 ]; then name="$stem (copy)$ext"; else name="$stem (copy $n)$ext"; fi
        n=$((n + 1))
    done
    if [ "$mode" = cut ]; then
        mv -- "$src" "$dest/$name" || status=1
    else
        cp -a -- "$src" "$dest/$name" || status=1
    fi
done
exit $status
