#!/usr/bin/env bash

while IFS=':' read -r key val; do
    val=${val// kB/}
    val=${val// /}
    case "$key" in
        MemTotal) total=$val ;;
        MemAvailable) available=$val ;;
        MemFree) free=$val ;;
        Cached) cached=$val ;;
        Buffers) buffers=$val ;;
        SwapTotal) swap_total=$val ;;
        SwapFree) swap_free=$val ;;
    esac
done < /proc/meminfo

used=$((total - available))
swap_used=$((swap_total - swap_free))

to_gb() {
    awk -v k="$1" 'BEGIN{printf "%.1f", k/1048576}'
}

total_gb=$(to_gb $total)
used_gb=$(to_gb $used)
free_gb=$(to_gb $free)
cached_gb=$(to_gb $cached)
buffers_gb=$(to_gb $buffers)
swap_total_gb=$(to_gb $swap_total)
swap_used_gb=$(to_gb $swap_used)

pct=$(( 100 * used / total ))

if [ "$pct" -ge 85 ]; then class="critical"; elif [ "$pct" -ge 60 ]; then class="warning"; else class="normal"; fi

tooltip="Used: ${used_gb} GB\n"
tooltip+="Free: ${free_gb} GB\n"
tooltip+="Cached: ${cached_gb} GB\n"
tooltip+="Buffers: ${buffers_gb} GB\n"
tooltip+="Swap: ${swap_used_gb} / ${swap_total_gb} GB\n"
tooltip+="Memory Pressure: ${pct}%"

echo "{\"text\": \" ${used_gb} / 48 GB\", \"tooltip\": \"${tooltip}\", \"class\": \"${class}\"}"
