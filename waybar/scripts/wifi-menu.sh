#!/usr/bin/env bash

# Rofi WiFi Menu
# Lists available networks, signal strength, lock status, refresh, and connection logic.
# Theme matching Waybar: #282c34 background, #56b6c2 cyan accent, #3b4252 item background.

notify() {
    notify-send -a "Waybar Wi-Fi" "$@"
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
    lines: 10;
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
    # Get WiFi radio state
    wifi_state=$(nmcli radio wifi)
    
    if [ "$wifi_state" = "enabled" ]; then
        toggle_option="󰖪  Disable Wi-Fi"
        
        # Rescan (asynchronously)
        nmcli dev wifi rescan &>/dev/null &
        
        # Get active SSID if connected
        active_ssid=$(nmcli -t -f active,ssid dev wifi 2>/dev/null | grep '^yes:' | cut -d':' -f2-)
        
        # Get available WiFi networks
        wifi_list=$(nmcli --fields ACTIVE,SSID,BARS,SECURITY,BSSID device wifi list 2>/dev/null | tail -n +2 | awk -F'  +' '
        {
            active = $1
            ssid = $2
            bars = $3
            security = $4
            bssid = $5
            
            if (ssid == "" || ssid == "--") {
                ssid = bssid " (Hidden)"
            }
            
            gsub(/^ */, "", ssid); gsub(/ *$/, "", ssid);
            gsub(/^ */, "", bars); gsub(/ *$/, "", bars);
            gsub(/^ */, "", security); gsub(/ *$/, "", security);
            
            lock = ""
            if (security != "" && security != "--") {
                lock = ""
            }
            
            if (active == "*") {
                printf "<b>* %s</b>\t[%s] %s\n", ssid, bars, lock
            } else {
                printf "%s\t[%s] %s\n", ssid, bars, lock
            }
        }
        ')
    else
        toggle_option="󰤨  Enable Wi-Fi"
        wifi_list=""
    fi
    
    if [ -n "$active_ssid" ]; then
        prompt="Connected: $active_ssid"
    else
        prompt="Wi-Fi Networks"
    fi
    
    options="$toggle_option\n󰑐  Refresh List\n󰤨  Manual Connection"
    if [ -n "$wifi_list" ]; then
        options="$options\n$wifi_list"
    fi
    
    selected=$(echo -e "$options" | rofi -dmenu -i -markup-rows -p "$prompt" -theme-str "$ROFI_THEME")
    
    if [ $? -ne 0 ] || [ -z "$selected" ]; then
        break
    fi
    
    selected=$(echo "$selected" | sed 's/^[ \t]*//;s/[ \t]*$//')
    
    if [[ "$selected" == *"Disable Wi-Fi"* ]]; then
        nmcli radio wifi off
        notify "Disabling Wi-Fi..."
        sleep 1
    elif [[ "$selected" == *"Enable Wi-Fi"* ]]; then
        nmcli radio wifi on
        notify "Enabling Wi-Fi..."
        sleep 2
    elif [[ "$selected" == *"Refresh List"* ]]; then
        notify "Scanning for networks..."
        nmcli dev wifi rescan
        sleep 2
    elif [[ "$selected" == *"Manual Connection"* ]]; then
        manual_ssid=$(echo "" | rofi -dmenu -p "SSID Name:" -theme-str "$ROFI_THEME")
        if [ -n "$manual_ssid" ]; then
            manual_pass=$(echo "" | rofi -dmenu -password -p "Password (blank if none):" -theme-str "$ROFI_THEME")
            if [ -n "$manual_pass" ]; then
                notify "Connecting to $manual_ssid..."
                if nmcli dev wifi connect "$manual_ssid" password "$manual_pass"; then
                    notify "Successfully connected to $manual_ssid!"
                else
                    notify "Failed to connect to $manual_ssid."
                fi
            else
                notify "Connecting to open network $manual_ssid..."
                if nmcli dev wifi connect "$manual_ssid"; then
                    notify "Successfully connected to $manual_ssid!"
                else
                    notify "Failed to connect to $manual_ssid."
                fi
            fi
        fi
        break
    else
        clean_ssid=$(echo "$selected" | sed 's/<b>\* //;s/<\/b>//')
        clean_ssid=$(echo "$clean_ssid" | cut -f1)
        
        # Check if active connection
        if [[ "$selected" == *"<b>*"* ]]; then
            confirm=$(echo -e "Disconnect\nCancel" | rofi -dmenu -p "Disconnect from $clean_ssid?" -theme-str "$ROFI_THEME")
            if [ "$confirm" = "Disconnect" ]; then
                nmcli device disconnect $(nmcli -t -f DEVICE,TYPE dev | grep wifi | cut -d':' -f1 | head -n1) 2>/dev/null
                notify "Disconnected from $clean_ssid"
            fi
            break
        fi
        
        # Check if saved
        saved_conn=$(nmcli -g NAME connection show 2>/dev/null | grep -F "$clean_ssid" | head -n1)
        saved_conn=$(echo "$saved_conn" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        if [ -n "$saved_conn" ]; then
            notify "Connecting to saved network $clean_ssid..."
            if nmcli connection up "$saved_conn"; then
                notify "Connected to $clean_ssid!"
            else
                notify "Failed to connect."
            fi
            break
        else
            if [[ "$selected" == *""* ]]; then
                password=$(echo "" | rofi -dmenu -password -p "Password for $clean_ssid:" -theme-str "$ROFI_THEME")
                if [ -n "$password" ]; then
                    notify "Connecting to $clean_ssid..."
                    if nmcli dev wifi connect "$clean_ssid" password "$password"; then
                        notify "Connected to $clean_ssid!"
                    else
                        notify "Connection failed."
                    fi
                fi
            else
                notify "Connecting to $clean_ssid..."
                if nmcli dev wifi connect "$clean_ssid"; then
                    notify "Connected to $clean_ssid!"
                else
                    notify "Connection failed."
                fi
            fi
            break
        fi
    fi
done
