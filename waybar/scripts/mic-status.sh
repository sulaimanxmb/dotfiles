#!/usr/bin/env bash

vol_out=$(wpctl get-volume @DEFAULT_SOURCE@ 2>/dev/null || echo "Volume: 0.00")
vol=$(echo "$vol_out" | awk '{print $2}')
muted=false
if [[ "$vol_out" == *MUTED* ]]; then muted=true; fi

vol_pct=$(awk -v v="$vol" 'BEGIN {print int(v * 100)}')

if $muted; then
    icon="󰍭"
    class="muted"
else
    icon="󰍬"
    class="active"
fi

desc=$(wpctl inspect @DEFAULT_SOURCE@ 2>/dev/null | awk -F '"' '/node.description/ {print $2}')
desc=${desc:-Unknown Input}

tooltip="Input Device: ${desc}\nInput Volume: ${vol_pct}%"

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$icon" "$tooltip" "$class"
