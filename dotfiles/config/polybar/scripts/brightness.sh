#!/bin/bash

# Get current brightness
current=$(brightnessctl get)
# Get max brightness
max=$(brightnessctl max)

# Calculate percentage
percentage=$((current * 100 / max))

# Display with icon
echo "󰃠 ${percentage}%"
