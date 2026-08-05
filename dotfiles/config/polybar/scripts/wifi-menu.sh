i#!/usr/bin/env bash
# wifi-menu.sh — Polybar WiFi click handler
# Scans for networks and shows a rofi/dmenu selector to connect/disconnect.
# Dependencies: nmcli, rofi (or dmenu), notify-send (optional)

# ── helpers ────────────────────────────────────────────────────────────────────
notify() {
    command -v notify-send &>/dev/null && notify-send "WiFi" "$1" --icon=network-wireless
}

# ── pick a menu launcher ───────────────────────────────────────────────────────
if command -v rofi &>/dev/null; then
    MENU() { rofi -dmenu -i -p "WiFi" -theme-str 'window {width: 400px;}'; }
elif command -v dmenu &>/dev/null; then
    MENU() { dmenu -i -p "WiFi:" -l 15; }
else
    notify "rofi or dmenu is required for the WiFi menu."
    exit 1
fi

# ── build network list ─────────────────────────────────────────────────────────
# Rescan (non-blocking) then list available networks
nmcli device wifi rescan 2>/dev/null &

CURRENT=$(nmcli -t -f active,ssid dev wifi | awk -F: '/^yes/{print $2}')

# Format: "▶ ConnectedNet  [saved]" or "  OpenNet" etc.
NETWORKS=$(nmcli -t -f active,ssid,signal,security dev wifi list 2>/dev/null \
    | sort -t: -k3 -rn \
    | awk -F: -v cur="$CURRENT" '
        !seen[$2]++ {
            active = ($1 == "yes") ? "▶ " : "  "
            ssid   = $2
            sig    = $3
            sec    = ($4 != "") ? " 🔒" : "   "
            # signal bar
            if      (sig+0 >= 80) bar="▂▄▆█"
            else if (sig+0 >= 60) bar="▂▄▆_"
            else if (sig+0 >= 40) bar="▂▄__"
            else if (sig+0 >= 20) bar="▂___"
            else                  bar="____"
            printf "%s%-30s %s%s\n", active, ssid, bar, sec
        }
    ')

# Extra actions at the bottom
ACTIONS=$'\n---\n  🔄 Rescan\n  ❌ Disconnect\n  ⚙  Edit connections'

CHOICE=$(printf '%s%s' "$NETWORKS" "$ACTIONS" | MENU)

[[ -z "$CHOICE" ]] && exit 0

# ── act on selection ───────────────────────────────────────────────────────────
# Extract SSID (trim leading active marker + spaces)
SSID=$(echo "$CHOICE" | sed 's/^[▶ ]*//' | awk '{print $1}')

case "$CHOICE" in
    *"Rescan"*)
        nmcli device wifi rescan
        notify "Rescanning for networks…"
        ;;
    *"Disconnect"*)
        nmcli device disconnect "$(nmcli -t -f device,type dev | awk -F: '/wifi/{print $1; exit}')"
        notify "Disconnected."
        ;;
    *"Edit connections"*)
        # nm-connection-editor is the standard GTK editor; fallback to nmtui
        if command -v nm-connection-editor &>/dev/null; then
            nm-connection-editor &
        else
            "${TERMINAL:-xterm}" -e nmtui &
        fi
        ;;
    *)
        # Try to connect — if a saved profile exists nmcli uses it silently
        if nmcli connection show "$SSID" &>/dev/null; then
            nmcli device wifi connect "$SSID" && notify "Connected to $SSID" || notify "Failed to connect to $SSID"
        else
            # Ask for password via rofi/dmenu
            if command -v rofi &>/dev/null; then
                PASS=$(rofi -dmenu -p "Password for $SSID:" -password -theme-str 'window {width: 350px;}')
            else
                PASS=$(dmenu -p "Password for $SSID:" </dev/null)
            fi
            [[ -z "$PASS" ]] && exit 0
            nmcli device wifi connect "$SSID" password "$PASS" \
                && notify "Connected to $SSID" \
                || notify "Failed to connect to $SSID"
        fi
        ;;
esac
