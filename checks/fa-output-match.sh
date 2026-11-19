#!/usr/bin/env bash
# w7G: fa-on output-match check - greedy stream equality, timing footer excluded.
set -euo pipefail
BIN=/home/joshuawarren/y-g5/llama-vulkan-bin
MODEL=/home/joshuawarren/models/gguf/Llama-3.2-1B-Instruct-Q8_0.gguf
export LD_LIBRARY_PATH="$BIN${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
export VK_ICD_FILENAMES=/usr/lib/omarchy-mlx/vulkan/honeykrisp_icd.aarch64.json
P="Explain in one short paragraph why the sky is blue during the day and orange at sunset."
D=/tmp/w7g_fa_match
mkdir -p "$D"
for fa in off on; do
  timeout 240 "$BIN/llama-cli" -m "$MODEL" -p "$P" -n 48 --temp 0 --seed 42 -ngl 99 -b 256 \
    -fa "$fa" --log-disable > "$D/out-$fa.txt" 2> "$D/err-$fa.txt"
  sed 's/\[ Prompt:[^\n]*//' "$D/out-$fa.txt" | grep -av 'Loading model' | tr -s ' ' > "$D/gen-$fa.txt"
done
echo "OFF_SHA=$(sha256sum < "$D/gen-off.txt" | cut -c1-16)"
echo "ON_SHA=$(sha256sum < "$D/gen-on.txt" | cut -c1-16)"
echo "GEN_TEXT=$(tail -c 150 "$D/gen-on.txt" | tr '\n' ' ')"
if cmp -s "$D/gen-off.txt" "$D/gen-on.txt"; then echo "MATCH=YES"; else echo "MATCH=NO"; diff "$D/gen-off.txt" "$D/gen-on.txt" | head -4; fi
