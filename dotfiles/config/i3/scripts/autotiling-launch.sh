#!/bin/sh
#
# ~/.config/i3/scripts/autotiling-launch.sh
#
# Restarts autotiling. Called from i3 exec_always, which fires once per
# reload/restart with no concurrency guard: two quick reloads ran the old
# inline pkill-then-spawn wrapper concurrently and the runs killed each
# other's fresh instance. The whole script therefore runs under flock;
# -o keeps the lock fd in the flock parent so the daemon spawned below
# doesn't inherit it and hold the lock forever.

if [ -z "${AUTOTILING_LAUNCH_LOCKED:-}" ]; then
    AUTOTILING_LAUNCH_LOCKED=1
    export AUTOTILING_LAUNCH_LOCKED
    exec flock -o -w 20 "${XDG_RUNTIME_DIR:-/tmp}/autotiling-launch.lock" "$0" "$@"
fi

command -v autotiling >/dev/null 2>&1 || exit 0

# Kill only the daemon, whose cmdline ends in ".../bin/autotiling".
# Never match the bare word "autotiling": it appears in this script's own
# cmdline too, and that self-match is what killed the old wrapper even on
# a single reload.
pkill -f 'bin/autotiling$'

i=0
while pgrep -f 'bin/autotiling$' >/dev/null && [ "$i" -lt 20 ]; do
    sleep 0.1
    i=$((i + 1))
done

autotiling >/tmp/autotiling.log 2>&1 &
