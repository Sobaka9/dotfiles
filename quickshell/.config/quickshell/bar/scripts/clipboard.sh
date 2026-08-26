#!/usr/bin/env bash
# Clipboard history for the launcher, as TSV: <id> <preview path or empty> <text>
#
# cliphist stores images as raw bytes and lists them as
# "[[ binary data 41 KiB png 992x690 ]]". To show them, each image entry is
# decoded once into a cache file that QML can point an Image at. Decoding is
# capped and cached, so a long history does not turn into a burst of work.
set -uo pipefail

cache="${XDG_CACHE_HOME:-$HOME/.cache}/quickshell-clip"
mkdir -p "$cache"

# Drop previews for entries that have aged out of the history.
find "$cache" -type f -mmin +2880 -delete 2>/dev/null

limit=40
decoded=0

while IFS=$'\t' read -r id rest; do
    [ -z "${id:-}" ] && continue
    preview=""

    if [[ "$rest" =~ ^\[\[[[:space:]]binary[[:space:]]data[[:space:]].*[[:space:]](png|jpg|jpeg|gif|bmp|webp)[[:space:]] ]]; then
        ext="${BASH_REMATCH[1]}"
        file="$cache/$id.$ext"
        if [ ! -s "$file" ] && [ "$decoded" -lt "$limit" ]; then
            if cliphist decode "$id" > "$file" 2>/dev/null && [ -s "$file" ]; then
                decoded=$((decoded + 1))
            else
                rm -f "$file"
            fi
        fi
        [ -s "$file" ] && preview="$file"
    fi

    printf '%s\t%s\t%s\n' "$id" "$preview" "$rest"
done < <(cliphist list)
