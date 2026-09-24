# workon / mkproject - open or create a project, wherever it lives
#
# Every decision lives in the Rust `projects` (built from rust/projects in the
# dotfiles repo with `just projects-install`); these functions only eval what
# it prints, because a cd and a virtualenv activation have to happen in this
# shell, not in a child process.
#
# `projects workon` exits non-zero with nothing on stdout when it fails, so a
# bad lookup never evals half an answer.
#
# The previous bash versions live on as `workon-archive` and
# `mkproject-archive` in ~/.bashrc.d/60-workon-archive.bash.

# On a Mac where the Rust `projects` has not been built yet, fall back to the
# archived versions rather than leaving `workon` undefined.
if ! command -v projects >/dev/null 2>&1; then
    workon() { workon-archive "$@"; }
    mkproject() { mkproject-archive "$@"; }
    return 0
fi

workon() {
    local code
    code="$(command projects workon "$@")" || return $?
    eval "$code"
}

mkproject() {
    local code
    code="$(command projects mkproject "$@")" || return $?
    eval "$code"
}

# No cache, unlike the archived bash version: the Python `projects list` took
# ~500ms to start, and this takes a few milliseconds.
_workon_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD - 1]}"

    if [[ "$prev" == "--host" || "$prev" == "--machine" ]]; then
        mapfile -t COMPREPLY < <(
            compgen -W "$(command projects machines list 2>/dev/null | awk '{print $1}')" -- "$cur"
        )
        return
    fi

    case "$cur" in
        --local=* | --remote=* | --auto=*)
            local flag="${cur%%=*}"
            local partial="${cur#*=}"
            mapfile -t COMPREPLY < <(
                compgen -P "${flag}=" -W "$(command projects names)" -- "$partial"
            )
            return
            ;;
        -*)
            mapfile -t COMPREPLY < <(
                compgen -W "--auto --local --remote --host --tmux --no-tmux --list --sessions --help" -- "$cur"
            )
            return
            ;;
    esac

    mapfile -t COMPREPLY < <(compgen -W "$(command projects names)" -- "$cur")
}

complete -F _workon_completions workon

_mkproject_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD - 1]}"

    case "$prev" in
        --machine | --host)
            mapfile -t COMPREPLY < <(
                compgen -W "$(command projects machines list 2>/dev/null | awk '{print $1}')" -- "$cur"
            )
            return
            ;;
        --python)
            mapfile -t COMPREPLY < <(compgen -W "3 3.11 3.12 3.13 3.14" -- "$cur")
            return
            ;;
    esac

    if [[ "$cur" == -* ]]; then
        mapfile -t COMPREPLY < <(
            compgen -W "--machine --host --path --work --session --tmux --no-tmux --python --no-attach --dry-run --help" -- "$cur"
        )
    fi
}

complete -F _mkproject_completions mkproject
