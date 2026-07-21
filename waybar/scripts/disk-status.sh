#!/usr/bin/env bash

PREV_FILE="/tmp/waybar_disk_prev"

read fs blocks used available pct mnt <<< $(df -BG / | tail -n 1)
pct_num=${pct//%/}

if [ "$pct_num" -ge 90 ]; then class="critical"; elif [ "$pct_num" -ge 70 ]; then class="warning"; else class="normal"; fi

# Calculate exact GB available for display text
avail_bytes=$(df -B1 / | awk 'NR==2 {print $4}')
avail_gb=$(awk -v b="$avail_bytes" 'BEGIN {printf "%.1f", b / 1073741824}')

read -r maj min name reads rmerged rsect rms writes wmerged wsect wms rest < <(grep 'nvme0n1 ' /proc/diskstats)
cur_time=$(date +%s%N)

if [ -f "$PREV_FILE" ]; then
    read prev_time prev_rsect prev_wsect < "$PREV_FILE"
else
    prev_time=$cur_time
    prev_rsect=$rsect
    prev_wsect=$wsect
fi
echo "$cur_time $rsect $wsect" > "$PREV_FILE"

tdiff=$(awk -v t1=$cur_time -v t2=$prev_time 'BEGIN{print (t1 - t2) / 1000000000}')
if awk -v td="$tdiff" 'BEGIN{exit (td > 0 ? 0 : 1)}'; then
    rspeed=$(awk -v r1=$rsect -v r2=$prev_rsect -v td=$tdiff 'BEGIN{printf "%.1f", ((r1 - r2) * 512) / (1048576 * td)}')
    wspeed=$(awk -v w1=$wsect -v w2=$prev_wsect -v td=$tdiff 'BEGIN{printf "%.1f", ((w1 - w2) * 512) / (1048576 * td)}')
else
    rspeed="0.0"
    wspeed="0.0"
fi

smart_out=$(smartctl -H /dev/nvme0n1 2>/dev/null | grep -i 'test result')
if echo "$smart_out" | grep -qi 'PASSED'; then
    smart_status="PASSED"
elif echo "$smart_out" | grep -qi 'FAILED'; then
    smart_status="FAILED"
else
    smart_status="N/A"
fi

temp_raw=$(cat /sys/class/hwmon/hwmon0/temp1_input 2>/dev/null || echo "0")
temp=$(awk -v t="$temp_raw" 'BEGIN{printf "%.1f", t/1000}')

tooltip="Root (/): ${used} / ${blocks} (${pct} used)\n"
tooltip+="Read: ${rspeed} MB/s | Write: ${wspeed} MB/s\n"
tooltip+="Filesystem: ext4\n"
tooltip+="SMART Health: ${smart_status}\n"
tooltip+="NVMe Temp: ${temp}°C"

echo "{\"text\": \" ${avail_gb} GB Free\", \"tooltip\": \"${tooltip}\", \"class\": \"${class}\"}"
