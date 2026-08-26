#!/usr/bin/env bash
# Apply a named theme: render every app's colours from the palette and
# live-reload each app. No session restart required.
#
# Usage: apply-theme.sh <theme-name>      (name = palette filename without .conf)
set -euo pipefail

THEME_DIR="$HOME/.config/themes"
PAL_DIR="$THEME_DIR/palettes"
TPL_DIR="$THEME_DIR/templates"
STATE="$THEME_DIR/.wallpaper-state"
WP_PID="$THEME_DIR/.wallpaper-pid"
WP_SCRIPT="$HOME/dotfiles/custom-scripts/start-wallpaperengine.sh"

name="${1:-}"
if [ -z "$name" ]; then
    echo "usage: $(basename "$0") <theme-name>" >&2
    echo "available:" >&2
    for f in "$PAL_DIR"/*.conf; do echo "  - $(basename "$f" .conf)" >&2; done
    exit 1
fi

pal="$PAL_DIR/$name.conf"
if [ ! -f "$pal" ]; then
    echo "error: no such theme '$name' ($pal not found)" >&2
    exit 1
fi

# Load palette and export every variable so envsubst can see them.
set -a
# shellcheck disable=SC1090
source "$pal"
border_angle_deg="${border_angle%deg}"
set +a

render() {  # render <template> <destination>
    local tpl="$TPL_DIR/$1" dst="$2"
    [ -f "$tpl" ] || { echo "warn: missing template $tpl" >&2; return; }
    mkdir -p "$(dirname "$dst")"
    envsubst < "$tpl" > "$dst"
}

echo ":: applying theme '$THEME_NAME'"

# --- render colour fragments / configs ---
render alacritty-colors.toml "$HOME/.config/alacritty/colors.toml"
render hypr-colors.lua       "$HOME/.config/hypr/colors.lua"

gtk_ini="$HOME/.config/gtk-3.0/settings.ini"
if [ -f "$gtk_ini" ]; then
    # --follow-symlinks edits the stow target in place, keeping the symlink.
    if grep -q '^gtk-theme-name=' "$gtk_ini"; then
        sed -i --follow-symlinks "s/^gtk-theme-name=.*/gtk-theme-name=$gtk_theme/" "$gtk_ini"
    else
        printf 'gtk-theme-name=%s\n' "$gtk_theme" >> "$gtk_ini"
    fi
fi
if command -v gsettings >/dev/null 2>&1; then
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "${gtk_color_scheme:-prefer-dark}" 2>/dev/null || true
fi

# --- Papirus folder colour ---
if [ -n "${folder_color:-}" ] && command -v papirus-folders >/dev/null 2>&1; then
    if ! sudo -n papirus-folders -C "$folder_color" --theme "${icon_theme:-Papirus}" >/dev/null 2>&1; then
        echo "warn: could not set folder colour '$folder_color'" \
             "(needs NOPASSWD sudo for papirus-folders)" >&2
    fi
fi

# --- live reloads ---
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl eval "hl.config({ general = { col = {
        active_border = { colors = { \"rgba(${border_active1})\", \"rgba(${border_active2})\" },
                          angle = ${border_angle_deg} },
        inactive_border = \"rgba(${border_inactive})\",
    } } })" >/dev/null 2>&1 || true
fi

# --- wallpaper engine (only restart if the wallpaper actually changed) ---
new_wp="${we_primary}|${we_secondary}|${we_nopause:-false}"
old_wp="$(cat "$STATE" 2>/dev/null || true)"
if [ "$new_wp" != "$old_wp" ] || ! pgrep -f linux-wallpaperengine >/dev/null 2>&1; then
    if [ -r "$WP_PID" ]; then
        old_pid="$(cat "$WP_PID" 2>/dev/null || true)"
        if [ -n "$old_pid" ] && grep -qs 'start-wallpaperengine' "/proc/$old_pid/cmdline"; then
            kill "$old_pid" 2>/dev/null || true
        fi
    fi
    sleep 0.3
    setsid "$WP_SCRIPT" \
        "$we_primary" "$we_secondary" "${we_nopause:-false}" >/dev/null 2>&1 &
    echo $! > "$WP_PID"
    echo "$new_wp" > "$STATE"
fi

echo "$name" > "$THEME_DIR/current"

# --- quickshell ---
render quickshell-colors.qml "$HOME/.config/quickshell/bar/Colors.qml"

notify-send -a "theme-switcher" "Theme applied" "$THEME_NAME" 2>/dev/null || true
echo ":: done"
