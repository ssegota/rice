#!/bin/bash

# Set your low battery percentage threshold
THRESHOLD=15

# Loop continuously
while true; do
    # Check if BAT0 exists (some laptops use BAT1 instead)
    if [ -d /sys/class/power_supply/BAT0 ]; then
        CAPACITY=$(cat /sys/class/power_supply/BAT0/capacity)
        STATUS=$(cat /sys/class/power_supply/BAT0/status)

        # If battery is discharging and drops to or below the threshold
        if [ "$STATUS" = "Discharging" ] && [ "$CAPACITY" -le $THRESHOLD ]; then
            notify-send -u critical "Battery Low" "Battery level is at ${CAPACITY}%!"
        fi
    fi
    
    # Wait 5 minutes (300 seconds) before checking again
    sleep 300
done
