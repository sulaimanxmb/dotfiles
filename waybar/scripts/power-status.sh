#!/usr/bin/env bash
# power-status.sh

TEXT="⏻"

UPTIME=$(uptime -p)
USER=$(whoami)
if [ -f /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor ]; then
    GOV=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor)
else
    GOV="N/A"
fi
LOAD=$(cat /proc/loadavg | awk '{print $1", "$2", "$3}')
LAST_BOOT=$(uptime -s)

TOOLTIP="<b>User:</b> $USER\n"
TOOLTIP+="<b>Uptime:</b> $UPTIME\n"
TOOLTIP+="<b>Last Boot:</b> $LAST_BOOT\n"
TOOLTIP+="<b>Power Profile:</b> $GOV\n"
TOOLTIP+="<b>System Load:</b> $LOAD"

TOOLTIP=$(echo "$TOOLTIP" | sed 's/"/\\"/g')

echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"normal\"}"
