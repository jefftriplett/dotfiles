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
    uvx --quiet rich --print "[green]get_env_details[/green]"

# virtualenvwrapper hook for environment initialization
initialize:
    #!/usr/bin/env sh
    # uvx --quiet rich --print "[green]initialize[/green]"
    :

# virtualenvwrapper hook that runs after environment activation
postactivate:
    #!/usr/bin/env sh
    VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    uvx --quiet rich --print "[green]postactivate[/green]"

# virtualenvwrapper hook that runs after environment deactivation
postdeactivate:
    #!/usr/bin/env sh
    # VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    uvx --quiet rich --print "[green]postdeactivate[/green]"

# virtualenvwrapper hook that runs after creating a project
postmkproject:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]postmkproject[/green]"

# virtualenvwrapper hook that runs after creating a virtualenv
postmkvirtualenv:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]postmkvirtualenv[/green]"
    python -m pip install --upgrade pip uv

# virtualenvwrapper hook that runs after removing a project
postrmproject:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]postrmproject[/green]"

# virtualenvwrapper hook that runs after removing a virtualenv
postrmvirtualenv:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]postrmvirtualenv[/green]"

# virtualenvwrapper hook that runs before environment activation
preactivate:
    #!/usr/bin/env sh
    # VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    uvx --quiet rich --print "[yellow]preactivate[/yellow]"

# virtualenvwrapper hook that runs before environment deactivation
predeactivate:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[yellow]predeactivate[/yellow]"

# virtualenvwrapper hook that runs before creating a project
premkproject:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[yellow]premkproject[/yellow]"

# virtualenvwrapper hook that runs before creating a virtualenv
premkvirtualenv:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[yellow]premkvirtualenv[/yellow]"

# virtualenvwrapper hook that runs before removing a project
prermproject:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[yellow]prermproject[/yellow]"

# virtualenvwrapper hook that runs before removing a virtualenv
prermvirtualenv:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[yellow]prermvirtualenv[/yellow]"
