#!/usr/bin/env bash

vol_out=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null || echo "Volume: 0.00")
vol=$(echo "$vol_out" | awk '{print $2}')
muted=false
if [[ "$vol_out" == *MUTED* ]]; then muted=true; fi

vol_pct=$(awk "BEGIN {print int($vol * 100)}")

if $muted; then
    icon="󰖁"
    class="muted"
elif [ "$vol_pct" -lt 30 ]; then
    icon="󰕿"
    class="normal"
elif [ "$vol_pct" -lt 70 ]; then
    icon="󰖀"
    class="normal"
else
    icon="󰕾"
    class="normal"
fi

text="${icon}  ${vol_pct}%"

desc=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk -F '"' '/node.description/ {print $2}')
desc=${desc:-Unknown Device}
backend="PipeWire"
sr=$(pw-cli info 0 2>/dev/null | awk '/default.clock.rate/ {print $NF}' | tr -d ',"')
sr=${sr:-48000}

# Parse active profile
prof=$(wpctl status 2>/dev/null | awk '/Sinks:/ {flag=1} flag && /\*/ {print; flag=0}' | sed -E 's/.*\* +[0-9]+ +\. (.*) \[vol:.*/\1/')
prof=${prof:-Unknown}

tooltip="Output Device: ${desc}\nActive Profile: ${prof}\nAudio Backend: ${backend}\nSample Rate: ${sr} Hz"

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$text" "$tooltip" "$class"
