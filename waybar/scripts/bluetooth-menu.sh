#!/usr/bin/env bash

# Rofi Bluetooth Menu
# Handles paired devices, connect/disconnect, scan for new devices, and power toggle.
# Theme matching Waybar: #282c34 background, #56b6c2 cyan accent, #3b4252 item background.

notify() {
    notify-send -a "Waybar Bluetooth" "$@"
}

ROFI_THEME='
window {
    background-color: #282c34;
    border: 2px solid;
    border-color: #56b6c2;
    border-radius: 6px;
    width: 440px;
    padding: 12px;
    font: "JetBrainsMono Nerd Font 11";
}
mainbox {
    background-color: transparent;
    children: [ inputbar, listview ];
}
inputbar {
    background-color: #3b4252;
    border-radius: 4px;
    padding: 8px 12px;
    margin: 0 0 10px 0;
    children: [ prompt, entry ];
}
prompt {
    background-color: transparent;
    text-color: #56b6c2;
    font: "JetBrainsMono Nerd Font Bold 11";
    margin: 0 8px 0 0;
}
entry {
    background-color: transparent;
    text-color: #abb2bf;
}
listview {
    background-color: transparent;
    lines: 8;
    columns: 1;
    spacing: 4px;
    scrollbar: false;
}
element {
    background-color: transparent;
    text-color: #abb2bf;
    padding: 8px 12px;
    border-radius: 4px;
}
element selected {
    background-color: #3b4252;
    text-color: #56b6c2;
}
element-text {
    background-color: transparent;
    text-color: inherit;
}
'

while true; do
    powered=$(bluetoothctl show 2>/dev/null | grep "Powered:" | awk '{print $2}')
    
    if [ "$powered" = "yes" ]; then
        toggle_option="󰂲  Disable Bluetooth"
        
        paired_devices=$(bluetoothctl devices 2>/dev/null | awk '{print $2, substr($0, index($0,$3))}')
        
        formatted_list=""
        while read -r mac name; do
            if [ -n "$mac" ]; then
                is_connected=$(bluetoothctl info "$mac" 2>/dev/null | grep "Connected:" | awk '{print $2}')
                if [ "$is_connected" = "yes" ]; then
                    formatted_list="${formatted_list}<b>* $name</b>\t[Connected] $mac\n"
                else
                    formatted_list="${formatted_list}$name\t[Paired] $mac\n"
                fi
            fi
        done <<< "$paired_devices"
    else
        toggle_option="  Enable Bluetooth"
        formatted_list=""
    fi
    
    prompt="Bluetooth"
    if [ "$powered" = "yes" ]; then
        prompt="Bluetooth: On"
    else
        prompt="Bluetooth: Off"
    fi
    
    options="$toggle_option\n󰑐  Scan for Devices\n󰂖  Refresh List"
    if [ -n "$formatted_list" ]; then
        options="$options\n$formatted_list"
    fi
    
    selected=$(echo -e "$options" | rofi -dmenu -i -markup-rows -p "$prompt" -theme-str "$ROFI_THEME")
    
    if [ $? -ne 0 ] || [ -z "$selected" ]; then
        break
    fi
    
    selected=$(echo "$selected" | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    if [[ "$selected" == *"Disable Bluetooth"* ]]; then
        bluetoothctl power off
        notify "Disabling Bluetooth..."
        sleep 1
    elif [[ "$selected" == *"Enable Bluetooth"* ]]; then
        bluetoothctl power on
        notify "Enabling Bluetooth..."
        sleep 2
    elif [[ "$selected" == *"Scan for Devices"* ]]; then
        notify "Scanning for nearby devices (10s)..."
        bluetoothctl --timeout 10 scan on &
        sleep 1
    elif [[ "$selected" == *"Refresh List"* ]]; then
        sleep 1
    else
        mac=$(echo "$selected" | awk '{print $NF}')
        name=$(echo "$selected" | sed -E 's/<b>\* //;s/<\/b>//' | cut -f1)
        
        if [[ ! "$mac" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; then
            notify "Invalid selection"
            continue
        fi
        
        if [[ "$selected" == *"<b>*"* ]] || [[ "$selected" == *"[Connected]"* ]]; then
            notify "Disconnecting from $name..."
            if bluetoothctl disconnect "$mac"; then
                notify "Disconnected from $name"
            else
                notify "Failed to disconnect"
            fi
            break
        else
            notify "Connecting to $name..."
            if bluetoothctl connect "$mac"; then
                notify "Connected to $name!"
            else
                notify "Failed to connect to $name"
            fi
            break
        fi
    fi
done
