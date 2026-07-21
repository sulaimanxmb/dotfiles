#!/usr/bin/env bash

svc_dir="$HOME/.config/systemd/user"
running=0
tooltip=""

if [ -d "$svc_dir" ]; then
    for svc_file in "$svc_dir"/*.service; do
        [ -e "$svc_file" ] || continue
        base=$(basename "$svc_file")
        name="${base%.service}"
        if systemctl --user is-active --quiet "$base"; then
            ((running++))
            tooltip+="✓ $name\n"
        else
            tooltip+="✗ $name\n"
        fi
    done
fi

if [ "$running" -eq 0 ]; then
    text=""
    class="inactive"
else
    text="⚙ $running"
    class="active"
fi

# Remove trailing newline from tooltip
tooltip=${tooltip%\\n}

printf '{"text": "%s", "tooltip": "%s", "class": "%s"}\n' "$text" "$tooltip" "$class"
