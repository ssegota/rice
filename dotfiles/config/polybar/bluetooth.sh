#!/usr/bin/env bash

status=$(bluetoothctl show | grep "Powered:" | awk '{print $2}')
connected=$(bluetoothctl info 2>/dev/null | grep "Name:" | sed 's/.*Name: //')

if [[ "$status" == "yes" ]]; then
    if [[ -n "$connected" ]]; then
        echo " $connected"
    else
        echo " On"
    fi
else
    echo " Off"
fi
