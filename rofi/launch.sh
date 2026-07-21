#!/usr/bin/env bash

# ═══════════════════════════════════════════════════════════════════════════
# Rofi Launcher — Modular Mode Wrapper
# Usage: launch.sh [mode]
#
# Modes:
#   drun        Application launcher (default)
#   run         Shell command runner
#   window      Window switcher
#   calc        Calculator (python3-based, copies result to clipboard)
#   file        File search (recursive from $HOME, opens with xdg-open)
#   emoji       Emoji picker (requires rofi-emoji)
#   clipboard   Clipboard history (requires cliphist)
#   all         Combined launcher (drun + run + window in single menu)
# ═══════════════════════════════════════════════════════════════════════════

CONFIG="$HOME/.config/rofi/config.rasi"
mode="${1:-drun}"

case "$mode" in

    # ── Application Launcher (Default) ──────────────────────────────────
    drun)
        rofi -show drun -config "$CONFIG"
        ;;

    # ── Shell Command Runner ────────────────────────────────────────────
    run)
        rofi -show run -config "$CONFIG"
        ;;

    # ── Window Switcher ─────────────────────────────────────────────────
    window)
        rofi -show window -config "$CONFIG"
        ;;

    # ── Combined Mode (apps + commands + windows in one) ────────────────
    all)
        rofi -show combi -combi-modi "drun,run,window" -config "$CONFIG"
        ;;

    # ── Calculator ──────────────────────────────────────────────────────
    calc)
        if command -v rofi-calc &>/dev/null; then
            # If rofi-calc plugin is installed, use it natively
            rofi -show calc -modi calc -no-show-match -no-sort -config "$CONFIG" \
                -calc-command "echo -n '{result}' | wl-copy"
        else
            # Fallback: custom python3-based calculator via script mode
            answer=$(echo "" | rofi -dmenu -p "🧮 Calc" -config "$CONFIG" \
                -theme-str 'listview { lines: 0; }')
            if [ -n "$answer" ]; then
                ~/.config/rofi/calc.sh "$answer"
            fi
        fi
        ;;

    # ── File Search ─────────────────────────────────────────────────────
    file)
        ~/.config/rofi/file-search.sh
        ;;

    # ── Emoji Picker ────────────────────────────────────────────────────
    emoji)
        if command -v rofimoji &>/dev/null; then
            rofimoji --action copy --skin-tone neutral
        else
            notify-send "Rofi Launcher" "rofimoji not installed.\nInstall with: sudo pacman -S rofimoji"
        fi
        ;;

    # ── Clipboard History ───────────────────────────────────────────────
    clipboard)
        if command -v cliphist &>/dev/null; then
            cliphist list | rofi -dmenu -p "📋 Clipboard" -config "$CONFIG" | cliphist decode | wl-copy
        else
            notify-send "Rofi Launcher" "cliphist not installed.\nInstall with: sudo pacman -S cliphist"
        fi
        ;;

    # ── Unknown Mode → Default to drun ──────────────────────────────────
    *)
        rofi -show drun -config "$CONFIG"
        ;;
esac
