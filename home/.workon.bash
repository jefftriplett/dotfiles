# workon - Project directory switcher with virtualenv activation
# Source this file in your .bashrc:
#   source ~/.workon.bash

# Directories to search for projects
WORKON_PROJECT_DIRS=("${HOME}/Projects" "${HOME}/Work")

# workon: Switch to a project directory and activate its virtualenv
workon() {
    local project_name="$1"

    if [[ -z "$project_name" ]]; then
        echo "Usage: workon <project_name>"
        echo "Available projects:"
        _workon_list_projects | sed 's/^/  /'
        return 1
    fi

    # Search for project in configured directories
    local project_dir=""
    for base_dir in "${WORKON_PROJECT_DIRS[@]}"; do
        if [[ -d "${base_dir}/${project_name}" ]]; then
            project_dir="${base_dir}/${project_name}"
            break
        fi
    done

    # Fallback to ~/.virtualenvs/<name> if no project dir found
    if [[ -z "$project_dir" ]]; then
        local venv_fallback="${HOME}/.virtualenvs/${project_name}"
        if [[ -f "${venv_fallback}/bin/activate" ]]; then
            # Deactivate any existing virtualenv
            if [[ -n "$VIRTUAL_ENV" ]]; then
                deactivate 2>/dev/null
            fi

            source "${venv_fallback}/bin/activate"

            # cd to src dir if it exists, otherwise stay put
            if [[ -d "${venv_fallback}/src" ]]; then
                cd "${venv_fallback}/src" || return 1
            fi

            if command -v uvx >/dev/null 2>&1; then
                uvx --quiet rich --print "[green]Activated[/green]: $project_name ([blue]${venv_fallback}[/blue])"
            else
                echo "Activated: $project_name (${venv_fallback})"
            fi
            return 0
        fi

        echo "Project not found: $project_name"
        echo "Searched in: ${WORKON_PROJECT_DIRS[*]} ~/.virtualenvs/"
        return 1
    fi

    # Change to project directory
    cd "$project_dir" || return 1

    # Look for and activate virtualenv
    local venv_candidates=(
        ".venv"
        "venv"
        "env"
        "${HOME}/.virtualenvs/${project_name}"
    )

    for venv_dir in "${venv_candidates[@]}"; do
        # Handle both relative and absolute paths
        local full_venv_path
        if [[ "$venv_dir" == /* ]]; then
            full_venv_path="$venv_dir"
        else
            full_venv_path="${project_dir}/${venv_dir}"
        fi

        if [[ -f "${full_venv_path}/bin/activate" ]]; then
            # Deactivate any existing virtualenv
            if [[ -n "$VIRTUAL_ENV" ]]; then
                deactivate 2>/dev/null
            fi

            source "${full_venv_path}/bin/activate"

            # For ~/.virtualenvs match, cd to src dir if it exists
            if [[ "$venv_dir" == /* && -d "${full_venv_path}/src" ]]; then
                cd "${full_venv_path}/src" || return 1
            fi

            if command -v uvx >/dev/null 2>&1; then
                uvx --quiet rich --print "[green]Activated[/green]: $project_name ([blue]${full_venv_path}[/blue])"
            else
                echo "Activated: $project_name (${full_venv_path})"
            fi
            return 0
        fi
    done

    # No virtualenv found, just notify
    if command -v uvx >/dev/null 2>&1; then
        uvx --quiet rich --print "[yellow]No virtualenv found for[/yellow]: $project_name"
    else
        echo "No virtualenv found for: $project_name"
    fi
}

# Helper: List all projects
_workon_list_projects() {
    {
        # List projects from configured directories
        for base_dir in "${WORKON_PROJECT_DIRS[@]}"; do
            if [[ -d "$base_dir" ]]; then
                for project in "$base_dir"/*/; do
                    if [[ -d "$project" ]]; then
                        project="${project%/}"
                        echo "${project##*/}"
                    fi
                done
            fi
        done

        # List virtualenvs from ~/.virtualenvs
        if [[ -d "${HOME}/.virtualenvs" ]]; then
            for venv in "${HOME}/.virtualenvs"/*/; do
                if [[ -f "${venv}bin/activate" ]]; then
                    venv="${venv%/}"
                    echo "${venv##*/}"
                fi
            done
        fi
    } | sort -u
}

# Bash completion for workon
_workon_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local projects
    projects=$(_workon_list_projects)
    COMPREPLY=($(compgen -W "$projects" -- "$cur"))
}

complete -F _workon_completions workon

# Default base directory for new projects
MKPROJECT_DEFAULT_DIR="${HOME}/Projects"

# mkproject: Create a new project with uv venv and direnv .envrc
# Usage: mkproject <project_name> [python_version] [base_dir]
mkproject() {
    local project_name="$1"
    local python_version="${2:-3}"  # Default to python3
    local base_dir="${3:-$MKPROJECT_DEFAULT_DIR}"

    if [[ -z "$project_name" ]]; then
        echo "Usage: mkproject <project_name> [python_version] [base_dir]"
        echo ""
        echo "Arguments:"
        echo "  project_name    Name of the project to create"
        echo "  python_version  Python version (default: 3, or specify like 3.11, 3.12, 3.13)"
        echo "  base_dir        Base directory (default: ~/Projects)"
        return 1
    fi

    local project_dir="${base_dir}/${project_name}"
    local venv_dir="${project_dir}/.venv"

    # Check if project already exists
    if [[ -d "$project_dir" ]]; then
        echo "Error: Project already exists: $project_dir"
        return 1
    fi

    if command -v uvx >/dev/null 2>&1; then
        uvx --quiet rich --print "[yellow]Creating project[/yellow]: $project_name"
        uvx --quiet rich --print "[blue]Location[/blue]: $project_dir"
        uvx --quiet rich --print "[blue]Python[/blue]: $python_version"
    else
        echo "Creating project: $project_name"
        echo "Location: $project_dir"
        echo "Python: $python_version"
    fi

    # Create project directory
    mkdir -p "$project_dir"

    # Create virtualenv with uv
    uv venv --python "$python_version" "$venv_dir"

    # Generate .envrc for direnv auto-activation
    echo 'source .venv/bin/activate' > "${project_dir}/.envrc"

    # Allow direnv for this project
    if command -v direnv >/dev/null 2>&1; then
        direnv allow "$project_dir"
    fi

    if command -v uvx >/dev/null 2>&1; then
        uvx --quiet rich --print "[green]Project created[/green]: $project_name"
        uvx --quiet rich --print "[green]Virtualenv created[/green]: $venv_dir"
        uvx --quiet rich --print "[green].envrc generated[/green] (direnv will auto-activate)"
    else
        echo "Project created: $project_name"
        echo "Virtualenv created: $venv_dir"
        echo ".envrc generated (direnv will auto-activate)"
    fi

    # Change to project and activate
    cd "$project_dir" || return 1
    source "$venv_dir/bin/activate"

    if command -v uvx >/dev/null 2>&1; then
        uvx --quiet rich --print "[green]Activated[/green]: $project_name"
    else
        echo "Activated: $project_name"
    fi
}

# Bash completion for mkproject
_mkproject_completions() {
    local cur="${COMP_WORDS[COMP_CWORD]}"

    case $COMP_CWORD in
        1)
            # First arg: no completion (new project name)
            COMPREPLY=()
            ;;
        2)
            # Second arg: python versions
            local pythons="3 3.10 3.11 3.12 3.13"
            if command -v pyenv >/dev/null 2>&1; then
                pythons="$pythons $(pyenv versions --bare 2>/dev/null | grep -E '^[0-9]' | tr '\n' ' ')"
            fi
            COMPREPLY=($(compgen -W "$pythons" -- "$cur"))
            ;;
        3)
            # Third arg: base directories
            local dirs="${HOME}/Projects ${HOME}/Work"
            COMPREPLY=($(compgen -W "$dirs" -- "$cur"))
            ;;
    esac
}

complete -F _mkproject_completions mkproject
