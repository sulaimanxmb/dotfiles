#!/usr/bin/env bash
# power-draw.sh
# Calculates live total and component power draw (CPU package, NVIDIA GPU, AMD iGPU).
# Refreshed every 5s via Waybar.

PREV_FILE="/tmp/waybar_power_prev"
CPU_ENERGY_FILE="/sys/devices/virtual/powercap/intel-rapl/intel-rapl:0/energy_uj"
AMD_GPU_FILE="/sys/class/hwmon/hwmon1/power1_input"

# 1. Calculate CPU Power (RAPL)
cpu_w=0.0
cpu_accessible=false

if [ -r "$CPU_ENERGY_FILE" ]; then
    cpu_accessible=true
    curr_energy=$(cat "$CPU_ENERGY_FILE")
    curr_time=$(date +%s.%N)
    
    if [ -f "$PREV_FILE" ]; then
        read -r prev_energy prev_time < "$PREV_FILE"
        
        # Calculate deltas
        diff_energy=$((curr_energy - prev_energy))
        # Use awk to handle floats for time difference
        diff_time=$(awk -v c="$curr_time" -v p="$prev_time" 'BEGIN {print c - p}')
        
        # Calculate Watts (microjoules to Joules, divided by seconds)
        if (( diff_energy > 0 )) && [ "$(awk -v dt="$diff_time" 'BEGIN {print (dt > 0) ? 1 : 0}')" -eq 1 ]; then
            cpu_w=$(awk -v de="$diff_energy" -v dt="$diff_time" 'BEGIN {printf "%.2f", (de / dt) / 1000000}')
        fi
    fi
    # Save for next iteration
    echo "$curr_energy $curr_time" > "$PREV_FILE"
fi

# 2. NVIDIA GPU Power (RTX 5060 Ti)
nv_w=0.0
nv_out=$(nvidia-smi --query-gpu=power.draw --format=csv,noheader,nounits 2>/dev/null)
if [ $? -eq 0 ] && [ -n "$nv_out" ]; then
    nv_w=$(echo "$nv_out" | xargs)
fi

# 3. AMD Integrated GPU Power
amd_w=0.0
if [ -f "$AMD_GPU_FILE" ]; then
    amd_raw=$(cat "$AMD_GPU_FILE" 2>/dev/null || echo "0")
    # Convert microwatts to Watts
    amd_w=$(awk -v r="$amd_raw" 'BEGIN {printf "%.2f", r / 1000000}')
fi

# 4. Sum up total
total_w=$(awk -v c="$cpu_w" -v n="$nv_w" -v a="$amd_w" 'BEGIN {printf "%.1f", c + n + a}')

# 5. Format tooltip and text
text="⚡ ${total_w} W"

if [ "$cpu_accessible" = "true" ]; then
    tooltip="<b>⚡ Power Consumption</b>\n"
    tooltip+="---------------------\n"
    tooltip+="<b>CPU Package:</b>  ${cpu_w} W\n"
    tooltip+="<b>NVIDIA GPU:</b>   ${nv_w} W\n"
    tooltip+="<b>AMD iGPU:</b>     ${amd_w} W\n"
    tooltip+="---------------------\n"
    tooltip+="<b>Active Total:</b> ${total_w} W"
else
    tooltip="<b>⚡ Power Consumption</b>\n"
    tooltip+="---------------------\n"
    tooltip+="<b>NVIDIA GPU:</b>   ${nv_w} W\n"
    tooltip+="<b>AMD iGPU:</b>     ${amd_w} W\n"
    tooltip+="---------------------\n"
    tooltip+="<b>Active Total:</b> ${total_w} W (GPU only)\n\n"
    tooltip+="<i>Note: Run the tmpfiles sudo command to enable CPU power tracking.</i>"
fi

# output json for waybar
echo "{\"text\": \"$text\", \"tooltip\": \"$tooltip\", \"class\": \"normal\"}"
