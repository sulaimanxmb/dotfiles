#!/usr/bin/env bash
# bluetooth-status.sh

# Check if bluetooth is powered on
POWERED=$(bluetoothctl show | grep "Powered: yes")

if [ -z "$POWERED" ]; then
    TOOLTIP="<b>Status:</b> Off"
    TOOLTIP=$(echo "$TOOLTIP" | sed 's/"/\\"/g')
    echo "{\"text\": \"󰂲 OFF\", \"tooltip\": \"$TOOLTIP\", \"class\": \"off\"}"
    exit 0
fi

# Check for connected devices
CONNECTED_DEVS=$(bluetoothctl devices Connected)

if [ -z "$CONNECTED_DEVS" ]; then
    ADAPTER=$(bluetoothctl show | grep "Name:" | cut -d: -f2 | xargs)
    TOOLTIP="<b>Status:</b> On\n<b>Adapter:</b> $ADAPTER\n<b>Connected Device:</b> None"
    TOOLTIP=$(echo "$TOOLTIP" | sed 's/"/\\"/g')
    echo "{\"text\": \"󰂯 ON\", \"tooltip\": \"$TOOLTIP\", \"class\": \"on\"}"
    exit 0
fi

# We have connected devices (take the first one)
MAC=$(echo "$CONNECTED_DEVS" | head -n1 | awk '{print $2}')
NAME=$(echo "$CONNECTED_DEVS" | head -n1 | cut -d' ' -f3-)

BATTERY=$(bluetoothctl info "$MAC" | grep "Battery Percentage" | awk '{print $4}' | tr -d '()')
if [ -z "$BATTERY" ]; then
    BATTERY="N/A"
else
    BATTERY="$BATTERY%"
fi

ADAPTER=$(bluetoothctl show | grep "Name:" | cut -d: -f2 | xargs)

TEXT=" $NAME"
TOOLTIP="<b>Status:</b> On\n<b>Adapter:</b> $ADAPTER\n<b>Connected Device:</b> $NAME\n<b>Device Battery:</b> $BATTERY"

TEXT=$(echo "$TEXT" | sed 's/"/\\"/g')
TOOLTIP=$(echo "$TOOLTIP" | sed 's/"/\\"/g')

echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"connected\"}"
