#!/usr/bin/env bash
# Send /restart to every Claude Code session that shows the update status.
#
# It reads the screen of every hc (herdr-core) terminal and every Herdr pane
# on this Mac and on each connected machine. A terminal that does not show
# "Update installed · Restart to update" is not touched.
#
# Usage: restart.sh [--dry-run]     WAIT=<seconds> sets the verify delay.
#
# Output lines (tab separated):
#   RESTARTED  <where>  <target>  <message>
#   FAILED     <where>  <target>  <reason>
#   SKIPPED    <where>  <target>  <reason>
#   FOUND      <where>  <target>  (dry run only)
set -u

HC=${HC:-$HOME/.local/bin/herdr-core}
PAT='Update installed · (Restart to update|/restart to apply)'
WAIT=${WAIT:-20}
DRY=0
[ "${1:-}" = "--dry-run" ] && DRY=1
HOST=$(hostname -s)
SENT=$(mktemp)
trap 'rm -f "$SENT"' EXIT

out() { printf '%s\t%s\t%s\t%s\n' "$@"; }

# herdr_cmd <machine> <args...>   (an empty machine means this Mac)
herdr_cmd() {
    local m=$1
    shift
    if [ -n "$m" ]; then herdr --machine "$m" "$@"; else herdr "$@"; fi
}

# screen <kind> <machine> <id>
screen() {
    # Claude Code puts a no-break space after the ❯ of the input line.
    case $1 in
        hc) "$HC" read "$3" ;;
        herdr) herdr_cmd "$2" pane read "$3" --source visible ;;
    esac 2>/dev/null | sed $'s/\xc2\xa0/ /g'
}

# keys <kind> <machine> <id> <key...>
keys() {
    local kind=$1 m=$2 id=$3
    shift 3
    case $kind in
        hc) "$HC" keys "$id" "$@" >/dev/null ;;
        herdr) herdr_cmd "$m" pane send-keys "$id" "$@" >/dev/null ;;
    esac
}

# Text after the last "❯ /restart" line on the screen.
after_restart() {
    awk '/^❯ \/restart/ {buf = ""; f = 1; next} f {buf = buf $0 "\n"} END {printf "%s", buf}'
}

# try <kind> <machine> <id> <status> <where>
try() {
    local kind=$1 m=$2 id=$3 status=$4 where=$5 scr line
    scr=$(screen "$kind" "$m" "$id")
    printf '%s\n' "$scr" | grep -Eq "$PAT" || return 0

    if [ "$kind" = hc ] && [ "$id" = "${HC_TERMINAL_ID:-}" ]; then
        out SKIPPED "$where" "$id" "this session"
        return 0
    fi
    if [ "$status" = working ] || printf '%s\n' "$scr" | grep -q 'esc to interrupt'; then
        out SKIPPED "$where" "$id" "working"
        return 0
    fi
    if [ "$DRY" = 1 ]; then
        out FOUND "$where" "$id" "-"
        return 0
    fi

    keys "$kind" "$m" "$id" / r e s t a r t
    sleep 1
    # Typing replaces a dim prompt suggestion but adds to a real draft.
    line=$(screen "$kind" "$m" "$id" | grep '^❯' | tail -n 1 | sed 's/[[:space:]]*$//')
    if [ "$line" != "❯ /restart" ]; then
        keys "$kind" "$m" "$id" backspace backspace backspace backspace \
            backspace backspace backspace backspace
        out SKIPPED "$where" "$id" "draft text in the prompt"
        return 0
    fi
    keys "$kind" "$m" "$id" enter
    printf '%s|%s|%s|%s\n' "$kind" "$m" "$id" "$where" >>"$SENT"
}

# --- hc terminals (this Mac and its connected machines) ---------------------
if [ -x "$HC" ] && hc_json=$("$HC" ls --json 2>/dev/null); then
    printf '%s\n' "$hc_json" | jq -r '.machines[] | select(.state != "connected") | .name' |
        while read -r m; do out SKIPPED "hc $m" "-" "machine not connected"; done
    while IFS=$'\t' read -r addr status where; do
        case $addr in
            */*) mach=${addr%%/*} ;;
            *) mach=$HOST ;;
        esac
        try hc "" "$addr" "$status" "hc $mach: $where"
    done < <(printf '%s\n' "$hc_json" | jq -r '.terminals[] | select(.state == "live") |
        [.address, (.status // "-"), .where] | @tsv')
fi

# --- Herdr panes (this Mac and each saved machine) --------------------------
if command -v herdr >/dev/null; then
    machines=("")
    while IFS=$'\t' read -r _ label state; do
        if [ "$state" = reachable ]; then
            machines+=("$label")
        else
            out SKIPPED "herdr $label" "-" "machine $state"
        fi
    done < <(herdr machine status 2>/dev/null)

    for m in "${machines[@]}"; do
        panes=$(herdr_cmd "$m" pane list 2>/dev/null) || continue
        spaces=$(herdr_cmd "$m" workspace list 2>/dev/null || echo '{}')
        while IFS=$'\t' read -r pane status ws; do
            # A pane that attaches to an hc terminal shows the same session.
            fg=$(herdr_cmd "$m" pane process-info --pane "$pane" 2>/dev/null |
                jq -r '.result.process_info.foreground_processes[0].argv[0] // ""')
            case ${fg##*/} in hc | herdr-core) continue ;; esac
            [ "$pane" = "${HERDR_PANE_ID:-}" ] && [ -z "$m" ] && continue
            try herdr "$m" "$pane" "$status" "herdr ${m:-$HOST}: $ws"
        done < <(jq -r --argjson s "$spaces" '
            ($s.result.workspaces // [] | map({(.workspace_id): .label}) | add // {}) as $w |
            .result.panes[] | [.pane_id, .agent_status, ($w[.workspace_id] // .workspace_id)] | @tsv' \
            <<<"$panes")
    done
fi

# --- Verify -------------------------------------------------------------------
[ -s "$SENT" ] || exit 0
sleep "$WAIT"
while IFS='|' read -r kind m id where; do
    res=$(screen "$kind" "$m" "$id" | after_restart)
    msg=$(printf '%s\n' "$res" | sed -n 's/^ *⎿ *//p' | head -n 1)
    case $res in
        *"Successfully updated"*) out RESTARTED "$where" "$id" "$msg" ;;
        *"Remote Control is connected"*) out FAILED "$where" "$id" "Remote Control connected" ;;
        *"belongs to"*) out FAILED "$where" "$id" "wrong directory: $msg" ;;
        *"Unknown command"*) out FAILED "$where" "$id" "old version: no /restart" ;;
        *) out FAILED "$where" "$id" "no result yet: ${msg:-empty screen}" ;;
    esac
done <"$SENT"
