#!/usr/bin/env bash
#
# ~/.config/polybar/launch.sh
#
# Launches "main" on the primary monitor and "secondary" on every other
# connected monitor, then starts the cursor watcher that autohides them.
#
# Writes /tmp/polybar-pids with one line per bar:
#     <name> <pid> <x> <y> <width> <height>
# so the autohide script never has to match names against xrandr.

set -u

PIDFILE=/tmp/polybar-pids
LOGDIR=/tmp
AUTOHIDE="$HOME/.config/polybar/scripts/polybar-autohide.sh"

# --- Kill existing bars and watcher -----------------------------------------
pkill -x polybar
pkill -f polybar-autohide.sh
while pgrep -x polybar >/dev/null; do sleep 0.2; done

: > "$PIDFILE"

# --- Enumerate monitors ------------------------------------------------------
# `polybar --list-monitors` prints e.g.
#     eDP-1: 1920x1080+0+0 (primary)
#     HDMI-1: 1920x1080+1920+0
mapfile -t MONS < <(polybar --list-monitors)

if (( ${#MONS[@]} == 0 )); then
    echo "launch.sh: polybar reports no monitors" >&2
    exit 1
fi

# Fall back to the first monitor if RandR has no primary flagged.
primary=""
for line in "${MONS[@]}"; do
    [[ "$line" == *"(primary)"* ]] && primary="${line%%:*}"
done
[[ -n "$primary" ]] || primary="${MONS[0]%%:*}"

# --- Launch one bar per monitor ---------------------------------------------
for line in "${MONS[@]}"; do
    name="${line%%:*}"
    geom="$(awk '{print $2}' <<< "$line")"

    if [[ ! "$geom" =~ ^([0-9]+)x([0-9]+)\+(-?[0-9]+)\+(-?[0-9]+)$ ]]; then
        echo "launch.sh: cannot parse geometry for $name ($geom), skipping" >&2
        continue
    fi
    w="${BASH_REMATCH[1]}"; h="${BASH_REMATCH[2]}"
    x="${BASH_REMATCH[3]}"; y="${BASH_REMATCH[4]}"

    if [[ "$name" == "$primary" ]]; then
        bar=main
    else
        bar=secondary
    fi

    MONITOR="$name" polybar --reload "$bar" > "$LOGDIR/polybar-$name.log" 2>&1 &
    pid=$!

    echo "$name $pid $x $y $w $h" >> "$PIDFILE"
    echo "launch.sh: $bar on $name (pid $pid) ${w}x${h}+${x}+${y}"
    sleep 0.2

    # Surface startup failures instead of hiding them.
    if ! kill -0 "$pid" 2>/dev/null; then
        echo "launch.sh: bar '$bar' died on $name -- see $LOGDIR/polybar-$name.log" >&2
    fi
done

# --- Start the autohide watcher ---------------------------------------------
if [[ -x "$AUTOHIDE" ]]; then
    "$AUTOHIDE" > "$LOGDIR/polybar-autohide.log" 2>&1 &
else
    echo "launch.sh: $AUTOHIDE missing or not executable; bars will stay hidden" >&2
fi
