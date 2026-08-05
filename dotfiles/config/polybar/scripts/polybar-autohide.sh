#!/usr/bin/env bash
#
# ~/.config/polybar/scripts/polybar-autohide.sh
#
# Watches the pointer and shows/hides each polybar instance over IPC.
# Reads "<name> <pid> <x> <y> <w> <h>" lines written by launch.sh, so it
# does not depend on xrandr names matching polybar's.
#
# Requires: xdotool, polybar 3.6+ (for `polybar-msg -p PID`).

set -u

BAR_HEIGHT=30       # must match `height` in config.ini
TRIGGER=2           # px from the top edge that reveals the bar
INTERVAL=0.1        # polling interval in seconds
PIDFILE=/tmp/polybar-pids

declare -A PID SHOWN MX MY MW MH

[[ -r "$PIDFILE" ]] || { echo "no $PIDFILE; run launch.sh first" >&2; exit 1; }

while read -r name pid x y w h; do
    [[ -n "${name:-}" ]] || continue
    PID[$name]=$pid
    MX[$name]=$x;  MY[$name]=$y
    MW[$name]=$w;  MH[$name]=$h
    SHOWN[$name]=0
done < "$PIDFILE"

(( ${#PID[@]} > 0 )) || { echo "$PIDFILE is empty" >&2; exit 1; }

echo "watching ${#PID[@]} bar(s): ${!PID[*]}"

# --- IPC helper --------------------------------------------------------------
# For polybar < 3.6 replace the body with:
#   echo "cmd:$2" > "/tmp/polybar_mqueue.${PID[$1]}"
msg() {
    polybar-msg -p "${PID[$1]}" cmd "$2" >/dev/null 2>&1
}

# Override-redirect windows are unmanaged, so nothing guarantees they stay
# on top. Raise explicitly whenever the bar is revealed.
raise() {
    local wid
    for wid in $(xdotool search --pid "${PID[$1]}" 2>/dev/null); do
        xdotool windowraise "$wid" 2>/dev/null
    done
}

show_bar() { msg "$1" show; raise "$1"; SHOWN[$1]=1; }
hide_bar() { msg "$1" hide; SHOWN[$1]=0; }

cleanup() {
    local m
    for m in "${!PID[@]}"; do msg "$m" hide; done
    exit 0
}
trap cleanup INT TERM

# --- Main loop ---------------------------------------------------------------
while true; do
    # Stop if every bar has gone away.
    alive=0
    for m in "${!PID[@]}"; do
        kill -0 "${PID[$m]}" 2>/dev/null && alive=1
    done
    (( alive )) || { echo "all bars exited"; exit 0; }

    eval "$(xdotool getmouselocation --shell)"

    for m in "${!PID[@]}"; do
        rel=$(( Y - MY[$m] ))

        if (( X >= MX[$m] && X < MX[$m] + MW[$m] && rel >= 0 && rel < MH[$m] )); then
            # Pointer is on this monitor
            if (( SHOWN[$m] == 0 && rel <= TRIGGER )); then
                show_bar "$m"
            elif (( SHOWN[$m] == 1 && rel > BAR_HEIGHT )); then
                hide_bar "$m"
            fi
        elif (( SHOWN[$m] == 1 )); then
            # Pointer left this monitor entirely
            hide_bar "$m"
        fi
    done

    sleep "$INTERVAL"
done
