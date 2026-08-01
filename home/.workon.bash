# workon - Open a project, wherever it lives
#
# Source this file in your .bashrc:
#   source ~/.workon.bash
#
# One command for local and remote. `workon <name>` consults the registry in
# ~/Projects/projects.toml: a project on this Mac is a cd + virtualenv
# activation, one on another Mac is a mosh in and a tmux attach. The old
# directory scan is still the fallback for anything unregistered, so a project
# you have never registered behaves exactly as it always did.
#
#   workon <name>                 auto (default): let the registry decide
#   workon --local[=<name>]       force local, even if it is registered elsewhere
#   workon --remote[=<name>]      force remote, using its registered machine
#   workon --host=<machine> <name>  open it on this machine instead
#
# --local and --remote take either form: `--local foo` or `--local=foo`.
#
# Local opens are a cd + activate, not a tmux attach -- that is what `workon`
# has always done and it stays fast. Add --tmux (or export WORKON_TMUX=1) to
# attach a session locally too. Remote opens always attach, since a tmux
# session is the thing being reached for.

# Directories to search for projects that are not in the registry
WORKON_PROJECT_DIRS=("${HOME}/Projects" "${HOME}/Work")

workon() {
    local mode="auto"
    local name=""
    local host=""
    local want_tmux="${WORKON_TMUX:-}"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                _workon_usage
                return 0
                ;;
            -l | --list)
                _workon_list_projects
                return 0
                ;;
            -s | --sessions)
                # Everything after this is for `projects sessions` (-m, -a,
                # --names), so hand the rest of the argv over untouched.
                shift
                projects sessions "$@"
                return $?
                ;;
            --auto)     mode="auto" ;;
            --auto=*)   mode="auto";   name="${1#*=}" ;;
            --local)    mode="local" ;;
            --local=*)  mode="local";  name="${1#*=}" ;;
            --remote)   mode="remote" ;;
            --remote=*) mode="remote"; name="${1#*=}" ;;
            --host | --machine)
                shift
                if [[ -z "${1:-}" ]]; then
                    echo "workon: --host needs a machine name" >&2
                    return 2
                fi
                host="$1"
                ;;
            --host=* | --machine=*)
                host="${1#*=}"
                ;;
            --tmux)     want_tmux=1 ;;
            --no-tmux)  want_tmux=0 ;;
            -*)
                echo "workon: unknown option: $1" >&2
                _workon_usage >&2
                return 2
                ;;
            *)
                if [[ -z "$name" ]]; then
                    name="$1"
                else
                    echo "workon: unexpected argument: $1" >&2
                    return 2
                fi
                ;;
        esac
        shift
    done

    if [[ -z "$name" ]]; then
        _workon_usage
        echo
        echo "Projects:"
        _workon_list_projects | sed 's/^/  /'
        return 1
    fi

    # --host implies "somewhere specific", which is a remote-style open unless
    # the machine named turns out to be this one -- `projects resolve` works
    # that out, so the mode stays auto and the answer decides.
    local resolve_args=("$name" "--shell")
    if [[ -n "$host" ]]; then
        resolve_args+=("--host" "$host")
    fi

    local resolved
    if ! resolved="$(projects resolve "${resolve_args[@]}" 2>/dev/null)"; then
        # Not in the registry. --remote and --host have nothing to work from,
        # so they are an error rather than a silent local open.
        if [[ "$mode" == "remote" || -n "$host" ]]; then
            echo "workon: $name is not in the registry, so it has no machine." >&2
            echo "Register it with: projects add $(printf '%q' "$name")" >&2
            return 1
        fi
        _workon_local_fallback "$name"
        return $?
    fi

    # All declared local so the eval below cannot leak resolver state into the
    # calling shell, even the fields this function does not read.
    # shellcheck disable=SC2034  # set by the eval; some are read only by callees
    local WORKON_RESOLVED_NAME WORKON_RESOLVED_KIND WORKON_RESOLVED_MACHINE
    # shellcheck disable=SC2034
    local WORKON_RESOLVED_HOST WORKON_RESOLVED_PATH WORKON_RESOLVED_PROJECT_PATH
    # shellcheck disable=SC2034
    local WORKON_RESOLVED_SESSION WORKON_RESOLVED_TMUX WORKON_RESOLVED_ARGV
    eval "$resolved"

    # A project with `tmux = false` stays a plain cd + activate even when asked
    # for a session, since it has deliberately opted out of one.
    if [[ -z "$WORKON_RESOLVED_TMUX" ]]; then
        want_tmux=0
    fi

    case "$mode" in
        local)
            _workon_open_local "$WORKON_RESOLVED_NAME" "$WORKON_RESOLVED_PATH" \
                "$WORKON_RESOLVED_SESSION" "$want_tmux"
            return $?
            ;;
        remote)
            if [[ "$WORKON_RESOLVED_KIND" != "remote" ]]; then
                # Two different situations, and the fix differs: a project
                # claimed by this machine, versus one that claims none and so
                # opens wherever you are. Reporting the second as "registered
                # to this machine ()" was both confusing and untrue.
                if [[ -n "$WORKON_RESOLVED_MACHINE" ]]; then
                    echo "workon: $WORKON_RESOLVED_NAME is registered to this machine (${WORKON_RESOLVED_MACHINE})." >&2
                else
                    echo "workon: $WORKON_RESOLVED_NAME has no machine, so it opens wherever you are." >&2
                    echo "Give it one with: projects set $(printf '%q' "$WORKON_RESOLVED_NAME") --machine <machine>" >&2
                fi
                echo "Use --host=<machine> to open it somewhere else." >&2
                return 1
            fi
            ;;
    esac

    if [[ "$WORKON_RESOLVED_KIND" == "remote" ]]; then
        _workon_open_remote
        return $?
    fi

    _workon_open_local "$WORKON_RESOLVED_NAME" "$WORKON_RESOLVED_PATH" \
        "$WORKON_RESOLVED_SESSION" "$want_tmux"
}

_workon_usage() {
    cat <<'EOF'
Usage: workon [--auto|--local|--remote] [--host=MACHINE] [--tmux] <project>

  workon notes                open it wherever the registry says it lives
  workon --local=pghub        force a local cd + activate
  workon --remote=pghub       force a mosh to its registered machine
  workon --host=studio pghub  open it on the Studio instead, just this once
  workon --list               list registered projects
  workon --sessions           show live tmux sessions on every Mac

--sessions passes its remaining arguments to `projects sessions`, so
`workon -s -a` is attached sessions only and `workon -s -m studio` is one Mac.

Local opens cd and activate the virtualenv. Add --tmux (or export WORKON_TMUX=1)
to attach a tmux session locally too; remote opens always attach one.
EOF
}

# Open a project on this machine: cd in, then either attach tmux or activate.
_workon_open_local() {
    local name="$1"
    local path="$2"
    local session="$3"
    local want_tmux="$4"

    # The registry stores "~/..." so a path means the same thing on every Mac;
    # expand it here for local use.
    path="${path/#\~/$HOME}"

    if [[ ! -d "$path" ]]; then
        echo "workon: $name is registered here but $path does not exist" >&2
        echo "Fix it with: projects add $(printf '%q' "$name") --force --path ..." >&2
        return 1
    fi

    cd "$path" || return 1

    if [[ "$want_tmux" == "1" ]]; then
        # In a subshell, and unsetting both host variables: the registry has
        # already told us this project is local, so a TMUX_AUTOATTACH_HOST left
        # over from the directory we came from must not send tmux-go over the
        # network. A `VAR=x tmux-go ...` prefix would not do -- assignments in
        # front of a *function* persist in the calling shell afterwards.
        (
            unset TMUX_AUTOATTACH_HOST TMUX_AUTOATTACH_MACHINE
            export TMUX_AUTOATTACH_PATH="$path"
            tmux-go "$session"
        )
        return $?
    fi

    _workon_activate "$path" "$name"
}

# Mosh (or ssh) to the machine and attach the session. Uses the argv the
# resolver built, which is already quoted for both hops.
_workon_open_remote() {
    if (( ${#WORKON_RESOLVED_ARGV[@]} == 0 )); then
        echo "workon: no command to reach $WORKON_RESOLVED_HOST" >&2
        return 1
    fi

    # Title the terminal tab before handing the session over, the way tmux-go
    # does -- once mosh takes the tty we no longer get to.
    printf '\033]0;%s\007' "${WORKON_RESOLVED_MACHINE}:${WORKON_RESOLVED_SESSION}"
    echo "workon: ${WORKON_RESOLVED_NAME} on ${WORKON_RESOLVED_MACHINE} (${WORKON_RESOLVED_HOST})" >&2

    # direnv exec / so the current project's direnv environment (which may
    # export TMUX_AUTOATTACH and re-trigger an attach) is out of the way.
    direnv exec / "${WORKON_RESOLVED_ARGV[@]}"
}

# Unregistered projects: the original directory scan, unchanged, so anything
# that worked before the registry existed still works.
_workon_local_fallback() {
    local name="$1"
    local base_dir project_dir=""

    for base_dir in "${WORKON_PROJECT_DIRS[@]}"; do
        if [[ -d "${base_dir}/${name}" ]]; then
            project_dir="${base_dir}/${name}"
            break
        fi
    done

    if [[ -z "$project_dir" ]]; then
        # Fall back to a bare ~/.virtualenvs/<name>, which has no project dir
        # of its own; cd into its src/ when it has one.
        local venv_fallback="${HOME}/.virtualenvs/${name}"
        if [[ -f "${venv_fallback}/bin/activate" ]]; then
            if [[ -n "$VIRTUAL_ENV" ]]; then
                deactivate 2>/dev/null
            fi
            # shellcheck source=/dev/null
            source "${venv_fallback}/bin/activate"
            if [[ -d "${venv_fallback}/src" ]]; then
                cd "${venv_fallback}/src" || return 1
            fi
            echo "Activated: ${name} (${venv_fallback})"
            return 0
        fi

        echo "workon: project not found: $name" >&2
        echo "Searched the registry, ${WORKON_PROJECT_DIRS[*]}, and ~/.virtualenvs/" >&2
        return 1
    fi

    cd "$project_dir" || return 1
    _workon_activate "$project_dir" "$name"
}

# Activate a project's virtualenv in the current shell.
_workon_activate() {
    local project_dir="$1"
    local name="$2"
    local venv_dir full_venv_path

    for venv_dir in ".venv" "venv" "env" "${HOME}/.virtualenvs/${name}"; do
        if [[ "$venv_dir" == /* ]]; then
            full_venv_path="$venv_dir"
        else
            full_venv_path="${project_dir}/${venv_dir}"
        fi

        if [[ -f "${full_venv_path}/bin/activate" ]]; then
            if [[ -n "$VIRTUAL_ENV" ]]; then
                deactivate 2>/dev/null
            fi
            # shellcheck source=/dev/null
            source "${full_venv_path}/bin/activate"
            echo "Activated: ${name} (${full_venv_path})"
            return 0
        fi
    done

    echo "No virtualenv found for: ${name}"
}

# Registered projects first, then any unregistered directory, so completion
# covers everything workon can actually open.
_workon_list_projects() {
    {
        projects list 2>/dev/null

        local base_dir project
        for base_dir in "${WORKON_PROJECT_DIRS[@]}"; do
            [[ -d "$base_dir" ]] || continue
            for project in "$base_dir"/*/; do
                [[ -d "$project" ]] || continue
                project="${project%/}"
                echo "${project##*/}"
            done
        done

        if [[ -d "${HOME}/.virtualenvs" ]]; then
            local venv
            for venv in "${HOME}/.virtualenvs"/*/; do
                if [[ -f "${venv}bin/activate" ]]; then
                    venv="${venv%/}"
                    echo "${venv##*/}"
                fi
            done
        fi
    } | sort -u
}

_workon_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD - 1]}"

    if [[ "$prev" == "--host" || "$prev" == "--machine" ]]; then
        mapfile -t COMPREPLY < <(
            compgen -W "$(projects machines 2>/dev/null | awk '{print $1}')" -- "$cur"
        )
        return
    fi

    case "$cur" in
        --local=* | --remote=* | --auto=*)
            local flag="${cur%%=*}"
            local partial="${cur#*=}"
            mapfile -t COMPREPLY < <(
                compgen -P "${flag}=" -W "$(_workon_list_projects)" -- "$partial"
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

    mapfile -t COMPREPLY < <(compgen -W "$(_workon_list_projects)" -- "$cur")
}

complete -F _workon_completions workon

# ---------------------------------------------------------------------------
# mkproject
# ---------------------------------------------------------------------------

# mkproject: create a project, register it, and open it.
# Delegates to `projects create`, which builds the directory, a uv venv, and an
# .envrc (layout uv + use tmux) here, then records it in the registry. Always
# here, even for a project owned by another Mac: ~/Projects and ~/Work are
# Syncthing folders, so the directory and .envrc arrive on their own, and
# `layout uv` builds a native venv the first time direnv sees it over there.
mkproject() {
    local name=""
    local attach=1
    local args=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h | --help)
                cat <<'EOF'
Usage: mkproject <name> [--machine KEY] [--host KEY] [--path DIR] [--work]
                        [--session NAME] [--tmux|--no-tmux]
                        [--python VERSION] [--no-attach] [--dry-run]

Creates the directory, a uv venv, and an .envrc (layout uv + use tmux) here,
registers it in ~/Projects/projects.toml, then opens it with workon. Syncthing
carries the directory to the other Macs; --machine only says which one owns it.

--work puts it under work_dir instead of home_dir; --path overrides both. No
machine is recorded unless you pass --machine, and a project without one opens
wherever you are.

--no-tmux registers the project with tmux off and leaves `use tmux` out of the
.envrc, so it is a plain cd + activate everywhere. --session names the session
when the project key is not what you want tmux to show.
EOF
                return 0
                ;;
            --no-attach)
                attach=0
                ;;
            --dry-run | -n)
                attach=0
                args+=("$1")
                ;;
            --host)
                shift
                args+=("--machine" "$1")
                ;;
            --host=*)
                args+=("--machine" "${1#*=}")
                ;;
            -*)
                args+=("$1")
                ;;
            *)
                if [[ -z "$name" ]]; then
                    name="$1"
                else
                    args+=("$1")
                fi
                ;;
        esac
        shift
    done

    if [[ -z "$name" ]]; then
        echo "Usage: mkproject <name> [options]  (--help for details)" >&2
        return 1
    fi

    projects create "$name" "${args[@]}" || return $?

    if (( attach )); then
        workon "$name"
    fi
}

_mkproject_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD - 1]}"

    case "$prev" in
        --machine | --host)
            mapfile -t COMPREPLY < <(
                compgen -W "$(projects machines 2>/dev/null | awk '{print $1}')" -- "$cur"
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
