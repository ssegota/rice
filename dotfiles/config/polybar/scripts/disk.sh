#!/bin/sh
used=$(df -h / | awk 'NR==2{print $3}')
total=$(df -h / | awk 'NR==2{print $2}')
echo "$used / $total"

