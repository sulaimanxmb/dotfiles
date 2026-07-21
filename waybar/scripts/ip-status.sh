#!/usr/bin/env bash

iface="wlp15s0"
ipv4=$(ip -4 addr show dev "$iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)

if [ -z "$ipv4" ]; then
    iface=$(ip -4 route ls 2>/dev/null | awk '/default/ {print $5}' | head -n1)
    if [ -n "$iface" ]; then
        ipv4=$(ip -4 addr show dev "$iface" 2>/dev/null | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1)
    fi
fi

if [ -z "$ipv4" ]; then
    printf '{"text": "No Network", "tooltip": "No active connection", "class": "disconnected"}\n'
    exit 0
fi

ipv6=$(ip -6 addr show dev "$iface" scope global 2>/dev/null | awk '/inet6 / {print $2}' | cut -d/ -f1 | head -n1)
ipv6=${ipv6:-None}

gw=$(ip route show default dev "$iface" 2>/dev/null | awk '{print $3}' | head -n1)
gw=${gw:-None}

mac=$(ip link show dev "$iface" 2>/dev/null | awk '/link\/ether/ {print $2}' | head -n1)
mac=${mac:-None}

tooltip="Interface: ${iface}\nIPv4: ${ipv4}\nIPv6: ${ipv6}\nGateway: ${gw}\nMAC: ${mac}"

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$ipv4" "$tooltip" "connected"
