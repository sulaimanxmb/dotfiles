#!/usr/bin/env bash

output=$(nvidia-smi --query-gpu=utilization.gpu,temperature.gpu,memory.used,memory.total,clocks.current.graphics,clocks.current.memory,fan.speed,power.draw --format=csv,noheader,nounits 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$output" ]; then
    echo "{\"text\": \" GPU --%\", \"tooltip\": \"nvidia-smi failed\", \"class\": \"normal\"}"
    exit 0
fi

IFS=',' read -r util temp vram_used vram_total clock_gfx clock_mem fan power <<< "$output"

util=$(echo $util | xargs)
temp=$(echo $temp | xargs)
vram_used=$(echo $vram_used | xargs)
vram_total=$(echo $vram_total | xargs)
clock_gfx=$(echo $clock_gfx | xargs)
clock_mem=$(echo $clock_mem | xargs)
fan=$(echo $fan | xargs)
power=$(echo $power | xargs)

if [ -z "$util" ] || [ "$util" = "[Not Supported]" ]; then
    util=0
fi

if [ "$util" -ge 80 ]; then class="critical"; elif [ "$util" -ge 50 ]; then class="warning"; else class="normal"; fi

tooltip="Temperature: ${temp}°C\n"
tooltip+="VRAM: ${vram_used} MB / ${vram_total} MB\n"
tooltip+="GPU Clock: ${clock_gfx} MHz\n"
tooltip+="Memory Clock: ${clock_mem} MHz\n"
tooltip+="Fan Speed: ${fan}%\n"
tooltip+="Power Draw: ${power} W"

echo "{\"text\": \" GPU ${util}%\", \"tooltip\": \"${tooltip}\", \"class\": \"${class}\"}"
