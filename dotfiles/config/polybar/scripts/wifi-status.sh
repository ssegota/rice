#!/usr/bin/env bash
# wifi-status.sh — Polybar WiFi label (left-click launches wifi-menu.sh)
# Outputs a short status string that polybar displays in the bar.
 
IFACE=$(nmcli -t -f device,type dev | awk -F: '/wifi/{print $1; exit}')
 
if [[ -z "$IFACE" ]]; then
    echo "󰤭 no wifi"
    exit 0
fi
 
STATE=$(nmcli -t -f device,state dev | awk -F: -v iface="$IFACE" '$1==iface{print $2}')
 
if [[ "$STATE" == "connected" ]]; then
    SSID=$(nmcli -t -f active,ssid dev wifi | awk -F: '/^yes/{print $2}')
    SIGNAL=$(nmcli -t -f in-use,signal dev wifi | awk -F: '/^\*/{print $2}')
 
    # pick icon by signal strength
    if   (( SIGNAL >= 80 )); then ICON="󰤨"
    elif (( SIGNAL >= 60 )); then ICON="󰤥"
    elif (( SIGNAL >= 40 )); then ICON="󰤢"
    elif (( SIGNAL >= 20 )); then ICON="󰤟"
    else                          ICON="󰤯"
    fi
 
    echo "$ICON $SSID (${SIGNAL}%)"
else
    echo "󰤭 disconnected"
fi
 
