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
set +a

render() {  # render <template> <destination>
    local tpl="$TPL_DIR/$1" dst="$2"
    [ -f "$tpl" ] || { echo "warn: missing template $tpl" >&2; return; }
    mkdir -p "$(dirname "$dst")"
    envsubst < "$tpl" > "$dst"
}

echo ":: applying theme '$THEME_NAME'"

# --- render colour fragments / configs ---
render waybar-colors.css   "$HOME/.config/waybar/colors.css"
render wofi-style.css       "$HOME/.config/wofi/style.css"
render alacritty-colors.toml "$HOME/.config/alacritty/colors.toml"
render hypr-colors.conf     "$HOME/.config/hypr/colors.conf"
render mako.config          "$HOME/.config/mako/config"
render quickshell-colors.qml "$HOME/.config/quickshell/bar/Colors.qml"

# --- GTK / QT (QT follows GTK via QT_QPA_PLATFORMTHEME=gtk3) ---
# No xsettings daemon runs under Hyprland here, so GTK apps read the theme
# from settings.ini at startup. This only works because GTK_THEME is NOT
# pinned in the Hyprland env (an env var would hard-override settings.ini).
# Running apps don't update live — reopen them to pick up the new theme.
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
# Papirus is root-owned (/usr/share/icons), so colouring folders needs sudo.
# For this to run from the keybind without a password prompt, add a NOPASSWD
# rule (one-time):
#   echo "$USER ALL=(root) NOPASSWD: /usr/bin/papirus-folders" \
#       | sudo tee /etc/sudoers.d/papirus-folders
# `sudo -n` never prompts, so without the rule this just warns and continues.
if [ -n "${folder_color:-}" ] && command -v papirus-folders >/dev/null 2>&1; then
    if ! sudo -n papirus-folders -C "$folder_color" --theme "${icon_theme:-Papirus}" >/dev/null 2>&1; then
        echo "warn: could not set folder colour '$folder_color'" \
             "(needs NOPASSWD sudo for papirus-folders)" >&2
    fi
fi

# --- live reloads ---
killall -SIGUSR2 waybar 2>/dev/null || true   # reload waybar style
# quickshell watches its QML files and reloads itself when Colors.qml changes.
makoctl reload 2>/dev/null || true            # reload mako config
# alacritty live-reloads colors.toml automatically.
if command -v hyprctl >/dev/null 2>&1; then
    hyprctl reload >/dev/null 2>&1 || true    # re-source hypr colours (won't relaunch apps)
    # Also set borders directly, so switching works regardless of whether the
    # active Hyprland config is hyprland.conf or hyprland.lua.
    hyprctl keyword general:col.active_border \
        "rgba(${border_active1}) rgba(${border_active2}) ${border_angle}" >/dev/null 2>&1 || true
    hyprctl keyword general:col.inactive_border \
        "rgba(${border_inactive})" >/dev/null 2>&1 || true
fi

# --- wallpaper engine (only restart if the wallpaper actually changed) ---
new_wp="${we_primary}|${we_secondary}|${we_nopause:-false}"
old_wp="$(cat "$STATE" 2>/dev/null || true)"
if [ "$new_wp" != "$old_wp" ] || ! pgrep -f linux-wallpaperengine >/dev/null 2>&1; then
    pkill -f 'start-wallpaperengine.sh' 2>/dev/null || true
    sleep 0.3
    setsid "$HOME/dotfiles/custom-scripts/start-wallpaperengine.sh" \
        "$we_primary" "$we_secondary" "${we_nopause:-false}" >/dev/null 2>&1 &
    echo "$new_wp" > "$STATE"
fi

echo "$name" > "$THEME_DIR/current"
notify-send -a "theme-switcher" "Theme applied" "$THEME_NAME" 2>/dev/null || true
echo ":: done"
