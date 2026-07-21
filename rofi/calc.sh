#!/usr/bin/env bash

# Rofi Calculator Launcher
# Evaluates math expressions using python3 and copies result to clipboard on Enter.

if [ -z "$1" ]; then
    echo "Enter expression (e.g. 15 * 4, 2^8, sqrt(256), pi * 10)..."
    exit 0
fi

query="$1"

# Evaluate using python3 safely
result=$(python3 -c "
import math
try:
    expr = '''$query'''.replace('^', '**')
    allowed = {k: v for k, v in math.__dict__.items() if not k.startswith('_')}
    allowed.update({'abs': abs, 'round': round, 'int': int, 'float': float})
    res = eval(expr, {'__builtins__': None}, allowed)
    if isinstance(res, float):
        print(f'{res:.6g}')
    else:
        print(res)
except Exception:
    print('')
" 2>/dev/null)

if [ -n "$result" ]; then
    echo "$result" | wl-copy 2>/dev/null
    notify-send -a "Calculator" "Result Copied!" "$query = $result" 2>/dev/null
    echo "= $result  (Copied to clipboard)"
else
    echo "Invalid expression"
fi
