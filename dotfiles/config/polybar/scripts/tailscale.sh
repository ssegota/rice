#!/usr/bin/env bash
#
# ~/.config/polybar/scripts/tailscale.sh
#
# Polybar module: Tailscale on/off with a colour indicator.
#   tailscale.sh          -> print status (eye green = connected, red = off,
#                            yellow = starting / needs login)
#   tailscale.sh toggle   -> tailscale up/down, then a desktop notification
#
# Colours come from the active polybar theme so the dot follows gundam-theme.
# Needs the user to be the tailscale operator once:
#     sudo tailscale set --operator=$USER

THEME="$HOME/.config/polybar/themes/gundam-active.ini"
color() { awk -F'=' -v k="$1" '$1 ~ "^"k"[ \t]*$" {gsub(/[ \t]/,"",$2); print $2; exit}' "$THEME"; }
ON=$(color eye);     ON=${ON:-#3f9e56}
OFF=$(color red);    OFF=${OFF:-#c0272d}
WAIT=$(color yellow-ink); WAIT=${WAIT:-#f0b929}
ICON="󰖂"

# One-time fix when we are not the tailscale operator yet: open a terminal that
# runs the sudo command, so the password prompt has somewhere to go.
grant_operator() {
  terminator -T "Tailscale: allow polybar toggle" -e "bash -c 'echo \"Allow $USER to switch Tailscale on/off without sudo:\"; sudo tailscale set --operator=$USER && echo Done. && $0 toggle; read -rp \"Press Enter to close\"'" &
}

state() { tailscale status --json 2>/dev/null | python3 -I -c 'import json,sys; print(json.load(sys.stdin).get("BackendState",""))' 2>/dev/null; }

case "${1:-}" in
  toggle)
    if [[ "$(state)" == "Running" ]]; then
      if out=$(tailscale down 2>&1); then
        notify-send -i network-vpn "Tailscale" "Disconnected — DNS and traffic go straight to your network"
      elif [[ "$out" == *"access denied"* ]]; then
        grant_operator
      else
        notify-send -u critical "Tailscale" "Could not disconnect: ${out:0:200}"
      fi
    else
      if out=$(tailscale up 2>&1); then
        notify-send -i network-vpn "Tailscale" "Connected — homelab reachable, Pi-hole DNS"
      elif [[ "$out" == *"access denied"* ]]; then
        grant_operator
      else
        notify-send -u critical "Tailscale" "Could not connect: ${out:0:200}"
      fi
    fi
    ;;
  *)
    case "$(state)" in
      Running)                 echo "%{F$ON}$ICON%{F-} TS" ;;
      Stopped)                 echo "%{F$OFF}$ICON%{F-} TS off" ;;
      Starting|NeedsLogin|NeedsMachineAuth) echo "%{F$WAIT}$ICON%{F-} TS…" ;;
      *)                       echo "%{F$OFF}$ICON%{F-} TS ?" ;;
    esac
    ;;
esac
