#!/usr/bin/env bash
# Wofi theme picker. Lists every palette with a wallpaper thumbnail,
# then applies the chosen theme.
set -euo pipefail

THEME_DIR="$HOME/.config/themes"
PAL_DIR="$THEME_DIR/palettes"

declare -A NAME_OF   # display name -> palette slug
menu=""

while IFS= read -r f; do
    slug="$(basename "$f" .conf)"
    disp="$(sed -n 's/^THEME_NAME="\(.*\)"/\1/p' "$f" | head -1)"
    prev="$(sed -n 's/^preview="\(.*\)"/\1/p' "$f" | head -1)"
    prev="${prev/\$HOME/$HOME}"        # expand $HOME if present
    prev="${prev/#\~/$HOME}"           # expand ~ if present
    [ -z "$disp" ] && disp="$slug"
    NAME_OF["$disp"]="$slug"
    if [ -n "$prev" ] && [ -f "$prev" ]; then
        menu+="img:${prev}:text:${disp}"$'\n'
    else
        menu+="${disp}"$'\n'
    fi
done < <(find "$PAL_DIR" -maxdepth 1 -name '*.conf' | sort)

sel="$(printf '%s' "$menu" | wofi --dmenu --allow-images --insensitive \
        --parse-search --prompt "Theme")" || exit 0
[ -z "$sel" ] && exit 0

# wofi returns the raw line; strip the "img:...:text:" prefix if present.
disp="${sel##*:text:}"
slug="${NAME_OF[$disp]:-$disp}"

exec "$THEME_DIR/apply-theme.sh" "$slug"
