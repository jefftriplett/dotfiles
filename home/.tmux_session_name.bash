# shellcheck shell=bash
#
# One definition of "what tmux session name does this project get", for the
# bash side of the toolchain. Sourced by ~/.bash_tmux and by use_tmux in
# ~/.config/direnv/direnvrc, which previously each carried their own copy with
# a "keep in sync with" comment on top -- a comment is not a mechanism, and the
# cost of drift is that the same project resolves to two different sessions
# depending on whether you arrived via `tmux-go` or via direnv.
#
# The Python half of this lives in session_slug() in ~/bin/_cmux.py. Two
# implementations rather than one is deliberate: collapsing them would mean
# bash shelling out to Python on the interactive attach path, and `projects`
# costs ~300ms to start, which is not a price worth paying on every `tmux-go`.
# Two is the floor; the contract is this file and that function agree.

# tmux session names may not contain ":" or "."; spaces are legal but a
# nuisance to type at `tmux attach -t`.
tmux_session_slug() {
    local name="$1"

    name="${name//:/-}"
    name="${name//./-}"
    name="${name// /-}"
    printf '%s' "$name"
}
