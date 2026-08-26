#!/usr/bin/env bash
# Take a screenshot, annotate it in satty, then copy + save it.
#
# Usage: screenshot.sh [region|window|monitor]
#   region   select an area with the mouse (default)
#   window   pick an open window
#   monitor  capture the currently focused monitor
#
# Requires: grim, slurp, hyprctl, jq, satty, wl-clipboard.

set -uo pipefail

mode="${1:-region}"
screenshots_dir="${SCREENSHOT_DIR:-$HOME/Pictures/screenshots}"
log="${XDG_RUNTIME_DIR:-/tmp}/screenshot.log"

raw="$(mktemp --tmpdir screenshot-XXXXXXXX.png)"
err="$(mktemp --tmpdir screenshot-XXXXXXXX.err)"
err_early="$(mktemp --tmpdir screenshot-XXXXXXXX.err)"
trap 'rm -f "$raw" "$err" "$err_early"' EXIT

note() { printf '%s  %s\n' "$(date -Is)" "$*" >>"$log"; }

fail() {
    note "FAIL: $*"
    notify-send -a screenshot -u critical "Screenshot failed" "$* — see $log" 2>/dev/null
    exit 1
}

grim_args=()
case "$mode" in
    region)
        geometry="$(slurp -d 2>"$err_early")" || exit 0
        [[ -n $geometry ]] || exit 0
        grim_args=(-g "$geometry")
        ;;
    window)
        # Offer every mapped window on the currently visible workspaces as a
        # snap target, the way hyprshot's window mode does.
        active_ids="$(hyprctl -j monitors | jq -r '[.[] | .activeWorkspace.id] | join(",")')"
        boxes="$(hyprctl -j clients |
            jq -r --argjson ids "[${active_ids}]" '
                .[] | select(.mapped and (.workspace.id as $w | $ids | index($w))) |
                "\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"')"
        [[ -n $boxes ]] || fail "no windows to pick from"
        geometry="$(slurp -r <<<"$boxes" 2>"$err_early")" || exit 0
        [[ -n $geometry ]] || exit 0
        grim_args=(-g "$geometry")
        ;;
    monitor | output)
        monitor_name="$(hyprctl -j monitors | jq -r '.[] | select(.focused) | .name')"
        [[ -n $monitor_name ]] || fail "could not determine the focused monitor"
        grim_args=(-o "$monitor_name")
        ;;
    *)
        echo "usage: ${0##*/} [region|window|monitor]" >&2
        exit 1
        ;;
esac

mkdir -p "$screenshots_dir"

if ! grim "${grim_args[@]}" - >"$raw" 2>"$err"; then
    fail "grim failed: $(tr '\n' ' ' <"$err" | cut -c1-160)"
fi

[[ -s $raw ]] || fail "grim produced an empty image"

sig="$(head -c 8 "$raw" | od -An -tx1 | tr -d ' \n')"
if [[ $sig != 89504e470d0a1a0a ]] || ! tail -c 16 "$raw" | grep -qa IEND; then
    cp -f "$raw" "$log.badcapture.png"
    fail "capture was not a complete PNG ($(stat -c%s "$raw") bytes, kept at $log.badcapture.png)"
fi

# The timestamp is expanded here rather than handed to satty as a strftime
# pattern, so we know the exact path satty saves to.
saved="$screenshots_dir/SS-$(date +%Y-%m-%d_%H-%M-%S).png"

# Enter copies to the clipboard, saves to disk and quits.
# Escape throws the screenshot away.
satty --filename "$raw" \
    --output-filename "$saved" \
    --copy-command wl-copy \
    --actions-on-enter save-to-clipboard,save-to-file \
    --actions-on-escape exit \
    --early-exit all \
    --initial-tool rectangle 2>"$err"
satty_rc=$?

satty_noise='config file not found|CSS overrides file|Fullscreen .*Floatinghack'
detail="$(grep -avE "$satty_noise" "$err" | tr '\n' ' ' | cut -c1-160)"

if [[ $satty_rc -ne 0 && $satty_rc -ne 130 && $satty_rc -ne 143 ]]; then
    fail "satty exited ${satty_rc}${detail:+: $detail}"
fi

if [[ -f $saved ]]; then
    wl-copy --type image/png <"$saved" || fail "could not copy $saved to the clipboard"
    note "saved $saved"
fi
