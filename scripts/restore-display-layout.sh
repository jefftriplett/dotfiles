#!/usr/bin/env bash
# Restore display layout: 4 monitors (2x 16" 1920x1080, 2x 73" 2048x1280)
#
# Layout:
#   ┌──────────────┐┌──────────────┐
#   │  73" 2048x1280││  73" 2048x1280│
#   │  (-2048,-1280)││  (0,-1280)    │
#   └──────────────┘└──────────────┘
#   ┌────────────┐┌────────────┐
#   │ 16" 1920x1080│ 16" 1920x1080│
#   │ (-1920,0)   ││ (0,0) MAIN  │
#   └────────────┘└────────────┘
#
# The two 73" displays have identical models so their persistent IDs
# can swap across reboots. Pass --swap to swap the top two displays,
# or run the script twice (it toggles automatically).

set -euo pipefail

STATE_FILE="${HOME}/.cache/displayplacer-swap-state"
SWAP=false

# Check for --swap flag
if [[ "${1:-}" == "--swap" ]]; then
    SWAP=true
fi

# Auto-toggle: if no flag passed, check if last run was recent (within 30s)
# and toggle the swap state (so a quick double-press swaps the top displays)
if [[ "$SWAP" == false && -f "$STATE_FILE" ]]; then
    last_run=$(cat "$STATE_FILE")
    now=$(date +%s)
    if (( now - last_run < 30 )); then
        SWAP=true
    fi
fi

# Save current timestamp
mkdir -p "$(dirname "$STATE_FILE")"
date +%s > "$STATE_FILE"

# Get displayplacer output once
DP_LIST=$(displayplacer list)

# Find the two 73" display IDs and the two 16" display IDs
get_displays_by_type() {
    local type_match="$1"
    echo "$DP_LIST" | awk -v tm="$type_match" '
        /Persistent screen id:/ { pid = $NF }
        /Type:/ && $0 ~ tm { print pid }
    '
}

# The 16" displays have stable IDs - match by current origin
get_id_by_origin() {
    local target_origin="$1"
    echo "$DP_LIST" | awk -v orig="$target_origin" '
        /Persistent screen id:/ { pid = $NF }
        /Origin:/ && index($0, orig) { print pid; exit }
    '
}

# Bottom displays (16") - identified by origin since they're stable
MAIN_ID=$(get_id_by_origin "(0,0)")
LEFT_ID=$(get_id_by_origin "(-1920,0)")

# Top displays (73") - get both IDs
TOP_IDS=($(get_displays_by_type "73 inch"))

if [[ ${#TOP_IDS[@]} -ne 2 ]]; then
    echo "Error: expected 2x 73\" displays, found ${#TOP_IDS[@]}" >&2
    exit 1
fi

# Assign top displays - swap if requested
if [[ "$SWAP" == true ]]; then
    TOP_RIGHT_ID="${TOP_IDS[1]}"
    TOP_LEFT_ID="${TOP_IDS[0]}"
    echo "Restoring layout (top displays swapped)"
else
    TOP_RIGHT_ID="${TOP_IDS[0]}"
    TOP_LEFT_ID="${TOP_IDS[1]}"
    echo "Restoring layout"
fi

# Verify we found all displays
for name_id in "main:$MAIN_ID" "left:$LEFT_ID" "top-right:$TOP_RIGHT_ID" "top-left:$TOP_LEFT_ID"; do
    name="${name_id%%:*}"
    id="${name_id##*:}"
    if [[ -z "$id" ]]; then
        echo "Error: could not find persistent ID for $name display" >&2
        exit 1
    fi
done

displayplacer \
  "id:${MAIN_ID} res:1920x1080 hz:60 color_depth:8 enabled:true scaling:off origin:(0,0) degree:0" \
  "id:${LEFT_ID} res:1920x1080 hz:60 color_depth:8 enabled:true scaling:off origin:(-1920,0) degree:0" \
  "id:${TOP_RIGHT_ID} res:2048x1280 hz:60 color_depth:8 enabled:true scaling:off origin:(0,-1280) degree:0" \
  "id:${TOP_LEFT_ID} res:2048x1280 hz:60 color_depth:8 enabled:true scaling:off origin:(-2048,-1280) degree:0"
