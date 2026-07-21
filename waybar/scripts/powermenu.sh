#!/usr/bin/env bash

# Rofi Power Menu
# Provides a simple system power menu integrated with Waybar.

ROFI_THEME='
window {
    background-color: #282c34;
    border: 2px solid;
    border-color: #56b6c2;
    border-radius: 6px;
    width: 320px;
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
    children: [ prompt ];
}
prompt {
    background-color: transparent;
    text-color: #56b6c2;
    font: "JetBrainsMono Nerd Font Bold 11";
}
listview {
    background-color: transparent;
    lines: 5;
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
    text-color: #e06c75;
}
element-text {
    background-color: transparent;
    text-color: inherit;
}
'

options="🔒  Lock\n󰍃  Logout\n󰤄  Suspend\n󰑐  Restart\n⏻  Shutdown"

chosen="$(echo -e "$options" | rofi -dmenu -i -p "Power Menu" -theme-str "$ROFI_THEME")"
case $chosen in
    *"Lock"*)
        loginctl lock-session
        ;;
    *"Logout"*)
        hyprctl dispatch exit
        ;;
    *"Suspend"*)
        systemctl suspend
        ;;
    *"Restart"*)
        systemctl reboot
        ;;
    *"Shutdown"*)
        systemctl poweroff
        ;;
esac
