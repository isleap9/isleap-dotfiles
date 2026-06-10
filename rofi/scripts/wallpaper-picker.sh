#!/usr/bin/env bash

WALLPAPER_DIR="$HOME/Pictures/Wallpapers"
CACHE_DIR="$HOME/.cache/rofi-wallpapers"
ROFI_THEME="$HOME/.config/rofi/wallpaper.rasi"

# ── Wallhaven config ──────────────────────────────────────────────────────────
WALLHAVEN_API_KEY=""        # optional — wallhaven.cc/settings/account
WALLHAVEN_RESOLUTION="1920x1080"
WALLHAVEN_CATEGORIES="111"
WALLHAVEN_PURITY="100"      # 100=SFW | 110=+Sketchy | 111=all (needs API key)
WALLHAVEN_SORTING="relevance"
WALLHAVEN_THUMB_DIR="/tmp/wallhaven-thumbs"
# ─────────────────────────────────────────────────────────────────────────────

mkdir -p "$CACHE_DIR" "$WALLHAVEN_THUMB_DIR"

API_ARGS=()
[[ -n "$WALLHAVEN_API_KEY" ]] && API_ARGS=(--header "X-API-Key: ${WALLHAVEN_API_KEY}")

# ── Apply wallpaper ───────────────────────────────────────────────────────────
apply_wallpaper() {
    local path="$1"
    if [[ -f "$HOME/.cache/dynamic-theme-enabled" ]]; then
        ~/.config/hypr/scripts/wallpaper-dynamic.sh "$path"
    else
        awww img "$path" \
            --transition-type fade \
            --transition-duration 2 \
            --transition-fps 60
    fi
}

# ── Fetch one page from wallhaven and append to arrays ───────────────────────
# Usage: fetch_page <encoded_query> <page> <ids_array> <urls_array> <thumbs_array>
fetch_page() {
    local encoded_query="$1"
    local page="$2"
    local -n _ids=$3
    local -n _urls=$4
    local -n _thumbs=$5

    local api_url="https://wallhaven.cc/api/v1/search"
    local params="q=${encoded_query}&categories=${WALLHAVEN_CATEGORIES}&purity=${WALLHAVEN_PURITY}&sorting=${WALLHAVEN_SORTING}&atleast=${WALLHAVEN_RESOLUTION}&per_page=24&page=${page}"

    local response
    response=$(curl -sf "${API_ARGS[@]}" "${api_url}?${params}")

    [[ -z "$response" ]] && return 1

    local count
    count=$(echo "$response" | jq '.data | length')
    [[ "$count" -eq 0 ]] && return 1

    notify-send "Wallpaper" "Fetching thumbnails (page ${page})…" --expire-time=2000

    while IFS=$'\t' read -r id full_url thumb_url; do
        local ext="${thumb_url##*.}"
        local thumb_path="${WALLHAVEN_THUMB_DIR}/${id}.${ext}"
        [[ ! -f "$thumb_path" ]] && curl -sf --max-time 10 -o "$thumb_path" "$thumb_url" 2>/dev/null
        _ids+=("$id")
        _urls+=("$full_url")
        _thumbs+=("$thumb_path")
    done < <(echo "$response" | jq -r '.data[] | [.id, .path, .thumbs.large] | @tsv')

    return 0
}

# ── Wallhaven search with pagination ─────────────────────────────────────────
wallhaven_search() {
    local query="$1"
    local page="${2:-1}"
    # Receive accumulated arrays from previous pages if Load More was used
    local -a wh_ids=("${!3}") wh_urls=("${!4}") wh_thumbs=("${!5}")

    local encoded_query
    encoded_query=$(python3 -c "import urllib.parse,sys; print(urllib.parse.quote(sys.argv[1]))" "$query")

    if ! fetch_page "$encoded_query" "$page" wh_ids wh_urls wh_thumbs; then
        if [[ "$page" -eq 1 ]]; then
            notify-send "Wallpaper" "No results for \"${query}\"." --urgency=normal
        else
            notify-send "Wallpaper" "No more results." --expire-time=2000
        fi
        return
    fi

    # Build tmpfile
    local WHTMP
    WHTMP=$(mktemp)

    printf "󰁍  Back\0icon\x1f%s\n"        "${wh_thumbs[0]}"  >> "$WHTMP"
    printf "󰇘  Load More…\0icon\x1f%s\n"  "${wh_thumbs[0]}"  >> "$WHTMP"

    for i in "${!wh_ids[@]}"; do
        printf "%s\0icon\x1f%s\n" "${wh_ids[$i]}" "${wh_thumbs[$i]}" >> "$WHTMP"
    done

    local total="${#wh_ids[@]}"
    local chosen
    chosen=$(rofi -dmenu -hover-select -me-select-entry "" -me-accept-entry "MousePrimary" -i \
        -p "wallhaven: ${query} (${total})" \
        -show-icons \
        -icon-size 160 \
        -format s \
        -config "$ROFI_THEME" < "$WHTMP")

    rm -f "$WHTMP"

    [[ -z "$chosen" ]] && return

    case "$chosen" in
        "󰁍  Back")
            return
            ;;
        "󰇘  Load More…")
            wallhaven_search "$query" $(( page + 1 )) "wh_ids[@]" "wh_urls[@]" "wh_thumbs[@]"
            return
            ;;
    esac

    # Find chosen URL
    local chosen_url=""
    for i in "${!wh_ids[@]}"; do
        if [[ "${wh_ids[$i]}" == "$chosen" ]]; then
            chosen_url="${wh_urls[$i]}"
            break
        fi
    done

    [[ -z "$chosen_url" ]] && return

    local ext="${chosen_url##*.}"
    local dest="${WALLPAPER_DIR}/wallhaven-${chosen}.${ext}"

    if [[ ! -f "$dest" ]]; then
        notify-send "Wallpaper" "Downloading wallpaper…" --expire-time=5000
        curl -sf "${API_ARGS[@]}" -o "$dest" "$chosen_url" || {
            notify-send "Wallpaper" "Download failed." --urgency=critical
            return
        }
    fi

    apply_wallpaper "$dest"
    notify-send "Wallpaper" "Set! Saved to ~/Pictures/Wallpapers/" --icon="$dest"
}

# ── Build local wallpaper entries ─────────────────────────────────────────────
declare -a names

for img in "$WALLPAPER_DIR"/*.{jpg,jpeg,png,gif,webp}; do
    [ -f "$img" ] || continue
    name=$(basename "$img")
    thumb="$CACHE_DIR/$name"
    if [ ! -f "$thumb" ]; then
        ffmpegthumbnailer -i "$img" -o "$thumb" -s 256 -q 10
    fi
    names+=("$name")
done

# ── Build tmpfile ─────────────────────────────────────────────────────────────
TMPFILE=$(mktemp)

printf "󰁍  Back\0icon\x1f%s/%s\n"              "$CACHE_DIR" "${names[0]}"  >> "$TMPFILE"
printf "🎲 Random Wallpaper\0icon\x1f%s/%s\n"  "$CACHE_DIR" "${names[0]}"  >> "$TMPFILE"
printf "󰋩  Search Wallhaven…\0icon\x1f%s/%s\n" "$CACHE_DIR" "${names[0]}"  >> "$TMPFILE"

for i in "${!names[@]}"; do
    printf "%s\0icon\x1f%s/%s\n" "${names[$i]}" "$CACHE_DIR" "${names[$i]}" >> "$TMPFILE"
done

# ── Show rofi ─────────────────────────────────────────────────────────────────
chosen=$(rofi -dmenu -hover-select -me-select-entry "" -me-accept-entry "MousePrimary" -i \
    -p "Select Wallpaper" \
    -show-icons \
    -icon-size 160 \
    -format s \
    -config "$ROFI_THEME" < "$TMPFILE")

rm -f "$TMPFILE"

[ -z "$chosen" ] && exit 0

case "$chosen" in
    "󰁍  Back")
        bash "$HOME/.config/rofi/scripts/control-center.sh"
        exit 0
        ;;
    "🎲 Random Wallpaper")
        chosen="${names[$RANDOM % ${#names[@]}]}"
        apply_wallpaper "$WALLPAPER_DIR/$chosen"
        ;;
    "󰋩  Search Wallhaven…")
        query=$(printf "" | rofi -dmenu -i \
            -p "Search wallhaven" \
            -config "$ROFI_THEME" \
            -theme-str "listview { lines: 0; }" \
            -mesg "e.g.  cyberpunk city   |   nature mountains   |   anime landscape")
        [[ -z "$query" ]] && exit 0
        wallhaven_search "$query"
        ;;
    *)
        apply_wallpaper "$WALLPAPER_DIR/$chosen"
        ;;
esac