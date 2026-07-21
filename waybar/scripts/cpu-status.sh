#!/usr/bin/env bash

PREV_FILE="/tmp/waybar_cpu_prev"
PREV_CORES_FILE="/tmp/waybar_cpu_cores_prev"

# 1. Total CPU
read cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
total=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_total=$((idle + iowait))

if [ -f "$PREV_FILE" ]; then
    read prev_total prev_idle < "$PREV_FILE"
else
    prev_total=0 prev_idle=0
fi
echo "$total $idle_total" > "$PREV_FILE"

diff_total=$((total - prev_total))
diff_idle=$((idle_total - prev_idle))
if [ "$diff_total" -eq 0 ]; then usage=0; else usage=$((100 * (diff_total - diff_idle) / diff_total)); fi

# 2. Temperature
temp_raw=$(cat /sys/class/hwmon/hwmon2/temp1_input 2>/dev/null || echo "0")
temp=$(awk -v t="$temp_raw" 'BEGIN{printf "%.1f", t/1000}')

# 3. Frequency
freq_raw=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq 2>/dev/null || echo "0")
freq=$(awk -v f="$freq_raw" 'BEGIN{printf "%.0f", f/1000}')

# 4. Load & Procs
read l1 l2 l3 procs rest < /proc/loadavg
load_avg="$l1, $l2, $l3"

# 5. Governor
governor=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo "N/A")

# 6. Threads
threads=$(grep -c '^cpu[0-9]' /proc/stat)

# 7. Per-Core Usage (Top 4)
top_cores=""
if [ -f "$PREV_CORES_FILE" ]; then
    top_cores=$(awk -v prev="$PREV_CORES_FILE" '
        BEGIN {
            while (getline < prev > 0) {
                if ($1 ~ /^cpu[0-9]+$/) {
                    p_tot[$1] = $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9;
                    p_idl[$1] = $5 + $6;
                }
            }
            close(prev);
        }
        /^cpu[0-9]+/ {
            tot = $2 + $3 + $4 + $5 + $6 + $7 + $8 + $9;
            idl = $5 + $6;
            dt = tot - p_tot[$1];
            di = idl - p_idl[$1];
            if (dt > 0) {
                pct = 100 * (dt - di) / dt;
                cores[$1] = pct;
            }
        }
        END {
            for (c in cores) print cores[c], c;
        }
    ' /proc/stat | sort -rn | head -n 4 | awk '{printf "%s: %.1f%%  ", $2, $1}')
fi
grep '^cpu[0-9]' /proc/stat > "$PREV_CORES_FILE"

# 8. Class
if [ "$usage" -ge 80 ]; then class="critical"; elif [ "$usage" -ge 50 ]; then class="warning"; else class="normal"; fi

# 9. Tooltip
tooltip="Temperature: ${temp}°C\n"
tooltip+="Frequency: ${freq} MHz\n"
tooltip+="Load Average: ${load_avg}\n"
tooltip+="Running Processes: ${procs}\n"
tooltip+="Threads: ${threads}\n"
tooltip+="Governor: ${governor}\n"
tooltip+="Top Cores: ${top_cores}"

echo "{\"text\": \" CPU ${usage}%\", \"tooltip\": \"${tooltip}\", \"class\": \"${class}\"}"
