#!/usr/bin/env bash

# Rofi File Search Script
# Searches files in $HOME and opens the selected file in Dolphin / default app.

target=$(find "$HOME" -maxdepth 4 \( -path '*/.*' -o -path '*/node_modules*' -o -path '*/__pycache__*' \) -prune -o -print 2>/dev/null | rofi -dmenu -i -p "📁 Search Files" -config ~/.config/rofi/config.rasi)

if [ -n "$target" ]; then
    xdg-open "$target" &>/dev/null &
fi
