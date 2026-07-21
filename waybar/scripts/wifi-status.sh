#!/usr/bin/env bash
# wifi-status.sh — WiFi status for Waybar custom/wifi module

INTERFACE="wlp15s0"

# Check if interface exists
if ! ip link show "$INTERFACE" > /dev/null 2>&1; then
    echo '{"text": "󰤮 Off", "tooltip": "Interface not found", "class": "disconnected"}'
    exit 0
fi

# Check if wifi radio is enabled
wifi_radio=$(nmcli radio wifi 2>/dev/null)
if [ "$wifi_radio" = "disabled" ]; then
    echo '{"text": "󰤮 Off", "tooltip": "WiFi radio is off", "class": "disconnected"}'
    exit 0
fi

# Check connection state
STATE=$(cat /sys/class/net/$INTERFACE/operstate 2>/dev/null)
if [ "$STATE" != "up" ]; then
    echo '{"text": "󰤮 Disconnected", "tooltip": "Disconnected", "class": "disconnected"}'
    exit 0
fi

# Get SSID via nmcli
SSID=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d':' -f2-)
if [ -z "$SSID" ]; then
    echo '{"text": "󰤮 Disconnected", "tooltip": "Disconnected", "class": "disconnected"}'
    exit 0
fi

# Signal strength from /proc/net/wireless (link quality out of 70)
LINK_QUALITY=$(awk "/$INTERFACE/ {print int(\$3)}" /proc/net/wireless 2>/dev/null)
SIGNAL_DBM=$(awk "/$INTERFACE/ {print int(\$4)}" /proc/net/wireless 2>/dev/null)

if [ -n "$LINK_QUALITY" ] && [ "$LINK_QUALITY" -gt 0 ]; then
    SIGNAL_PCT=$(( LINK_QUALITY * 100 / 70 ))
    [ "$SIGNAL_PCT" -gt 100 ] && SIGNAL_PCT=100
else
    # Fallback: get signal from nmcli
    SIGNAL_PCT=$(nmcli -t -f active,signal dev wifi 2>/dev/null | grep '^yes:' | cut -d':' -f2)
    SIGNAL_PCT=${SIGNAL_PCT:-0}
fi

# Icons based on signal %
if [ "$SIGNAL_PCT" -lt 20 ]; then ICON="󰤯"
elif [ "$SIGNAL_PCT" -lt 40 ]; then ICON="󰤟"
elif [ "$SIGNAL_PCT" -lt 60 ]; then ICON="󰤢"
elif [ "$SIGNAL_PCT" -lt 80 ]; then ICON="󰤥"
else ICON="󰤨"
fi

TEXT="$ICON $SSID"

# Speed calculation (bytes/sec delta)
PREV_FILE="/tmp/waybar_wifi_prev"
CUR_RX=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
CUR_TX=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
CUR_TIME=$(date +%s)

if [ -f "$PREV_FILE" ]; then
    read PREV_RX PREV_TX PREV_TIME < "$PREV_FILE"
    TIME_DIFF=$(( CUR_TIME - PREV_TIME ))
    if [ "$TIME_DIFF" -gt 0 ]; then
        RX_SPD=$(( (CUR_RX - PREV_RX) / TIME_DIFF ))
        TX_SPD=$(( (CUR_TX - PREV_TX) / TIME_DIFF ))

        if [ "$RX_SPD" -gt 1048576 ]; then
            RX_STR=$(awk -v s="$RX_SPD" 'BEGIN {printf "%.1f MB/s", s/1048576}')
        else
            RX_STR=$(awk -v s="$RX_SPD" 'BEGIN {printf "%.1f KB/s", s/1024}')
        fi
        if [ "$TX_SPD" -gt 1048576 ]; then
            TX_STR=$(awk -v s="$TX_SPD" 'BEGIN {printf "%.1f MB/s", s/1048576}')
        else
            TX_STR=$(awk -v s="$TX_SPD" 'BEGIN {printf "%.1f KB/s", s/1024}')
        fi
    else
        RX_STR="-- KB/s"
        TX_STR="-- KB/s"
    fi
else
    RX_STR="-- KB/s"
    TX_STR="-- KB/s"
fi

echo "$CUR_RX $CUR_TX $CUR_TIME" > "$PREV_FILE"

# Link speed from nmcli
LINK_SPEED=$(nmcli -f GENERAL.SPEED dev show "$INTERFACE" 2>/dev/null | awk '{print $2, $3}')
LINK_SPEED=${LINK_SPEED:-"N/A"}

# IPv4, Gateway, DNS
IPV4=$(ip -4 addr show dev "$INTERFACE" 2>/dev/null | grep inet | awk '{print $2}' | cut -d/ -f1)
GATEWAY=$(ip route show default dev "$INTERFACE" 2>/dev/null | awk '{print $3}')
DNS=$(resolvectl dns "$INTERFACE" 2>/dev/null | awk '{for(i=4;i<=NF;i++) print $i}' | tr '\n' ' ' | xargs)
if [ -z "$DNS" ]; then
    DNS=$(grep nameserver /etc/resolv.conf 2>/dev/null | awk '{print $2}' | head -2 | tr '\n' ' ' | xargs)
fi

# Build tooltip
TOOLTIP="WiFi: $SSID\n"
TOOLTIP+="Signal: ${SIGNAL_PCT}%"
[ -n "$SIGNAL_DBM" ] && TOOLTIP+=" (${SIGNAL_DBM} dBm)"
TOOLTIP+="\nDownload: $RX_STR\nUpload: $TX_STR"
TOOLTIP+="\nLink Speed: $LINK_SPEED"
TOOLTIP+="\nIPv4: ${IPV4:-N/A}"
TOOLTIP+="\nGateway: ${GATEWAY:-N/A}"
TOOLTIP+="\nDNS: ${DNS:-N/A}"

# Escape double quotes in text and tooltip for JSON
TEXT=$(echo "$TEXT" | sed 's/"/\\"/g')
TOOLTIP=$(echo "$TOOLTIP" | sed 's/"/\\"/g')

echo "{\"text\": \"$TEXT\", \"tooltip\": \"$TOOLTIP\", \"class\": \"connected\"}"
