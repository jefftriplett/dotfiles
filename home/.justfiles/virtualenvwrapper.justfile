# ----------------------------------------------------------------
# virtualenvwrapper recipes
# ----------------------------------------------------------------

set dotenv-load := false
set export := true

justfile := justfile_directory() + "/.justfiles/virtualenvwrapper.justfile"

[private]
@default:
    just --justfile {{ justfile }} --list

[private]
@fmt:
    just --justfile {{ justfile }} --fmt

# ----------------------------------------------------------------
# virtualenvwrapper hooks
# ----------------------------------------------------------------

# virtualenvwrapper hook for getting environment details
get_env_details:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]virtualenvwrapper::get_env_details[/green]"

# virtualenvwrapper hook for environment initialization
initialize:
    #!/usr/bin/env sh
    # uvx --quiet rich --print "[green]initialize[/green]"
    # Set PROJECT_HOME if not already set
    if [ -z "${PROJECT_HOME}" ]; then
        export PROJECT_HOME="${HOME}/Projects"
    fi

    # Ensure PROJECT_HOME directory exists
    if [ ! -d "${PROJECT_HOME}" ]; then
        mkdir -p "${PROJECT_HOME}"
    fi

#     uvx --quiet rich --print "[blue]PROJECT_HOME[/blue]: ${PROJECT_HOME}"

# virtualenvwrapper hook that runs after environment activation
postactivate:
    #!/usr/bin/env sh
    VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    uvx --quiet rich --print "[green]virtualenvwrapper::postactivate[/green]"

# virtualenvwrapper hook that runs after environment deactivation
postdeactivate:
    #!/usr/bin/env sh
    # VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    uvx --quiet rich --print "[green]virtualenvwrapper::postdeactivate[/green]"

# virtualenvwrapper hook that runs after creating a project
postmkproject:
    #!/usr/bin/env sh
    VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    PROJECT_DIR="${PROJECT_HOME}/${VIRTUAL_ENV_NAME}"

    uvx --quiet rich --print "[green]virtualenvwrapper::postmkproject[/green]"
    uvx --quiet rich --print "[blue]Project created[/blue]: ${PROJECT_DIR}"

# virtualenvwrapper hook that runs after creating a virtualenv
postmkvirtualenv:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]virtualenvwrapper::postmkvirtualenv[/green]"
    python -m pip install --upgrade pip uv

# virtualenvwrapper hook that runs after removing a project
postrmproject:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]virtualenvwrapper::postrmproject[/green]"

# virtualenvwrapper hook that runs after removing a virtualenv
postrmvirtualenv:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]virtualenvwrapper::postrmvirtualenv[/green]"

# virtualenvwrapper hook that runs before environment activation
preactivate:
    #!/usr/bin/env sh
    # VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    uvx --quiet rich --print "[yellow]virtualenvwrapper::preactivate[/yellow]"

# virtualenvwrapper hook that runs before environment deactivation
predeactivate:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[yellow]virtualenvwrapper::predeactivate[/yellow]"

# virtualenvwrapper hook that runs before creating a project
premkproject:
    #!/usr/bin/env sh
    # Ensure PROJECT_HOME is set
    if [ -z "${PROJECT_HOME}" ]; then
        export PROJECT_HOME="${HOME}/Projects"
    fi

    # Ensure PROJECT_HOME directory exists
    if [ ! -d "${PROJECT_HOME}" ]; then
        mkdir -p "${PROJECT_HOME}"
    fi

    uvx --quiet rich --print "[yellow]virtualenvwrapper::premkproject[/yellow]"
    uvx --quiet rich --print "[blue]PROJECT_HOME[/blue]: ${PROJECT_HOME}"

# virtualenvwrapper hook that runs before creating a virtualenv
premkvirtualenv:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[yellow]virtualenvwrapper::premkvirtualenv[/yellow]"

# virtualenvwrapper hook that runs before removing a project
prermproject:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[yellow]virtualenvwrapper::prermproject[/yellow]"

# virtualenvwrapper hook that runs before removing a virtualenv
prermvirtualenv:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[yellow]virtualenvwrapper::prermvirtualenv[/yellow]"
