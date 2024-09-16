# ----------------------------------------------------------------
# virtualenvwrapper recipes
# ----------------------------------------------------------------

justfile := justfile_directory() + "/.justfiles/virtualenvwrapper.justfile"

@_default:
    just --list

@_fmt:
    just --fmt --justfile {{ justfile }}

# ----------------------------------------------------------------
# virtualenvwrapper hooks
# ----------------------------------------------------------------

get_env_details:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]get_env_details[/green]"

initialize:
    #!/usr/bin/env sh
    # uvx --quiet rich --print "[green]initialize[/green]"
    :

postactivate:
    #!/usr/bin/env sh
    VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    uvx --quiet rich --print "[green]postactivate[/green]"

postdeactivate:
    #!/usr/bin/env sh
    # VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    uvx --quiet rich --print "[green]postdeactivate[/green]"

postmkproject:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]postmkproject[/green]"

postmkvirtualenv:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]postmkvirtualenv[/green]"
    python -m pip install --upgrade pip uv

postrmproject:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]postrmproject[/green]"

postrmvirtualenv:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]postrmvirtualenv[/green]"

preactivate:
    #!/usr/bin/env sh
    # VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    uvx --quiet rich --print "[green]preactivate[/green]"

predeactivate:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]predeactivate[/green]"

premkproject:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]premkproject[/green]"

premkvirtualenv:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]premkvirtualenv[/green]"

prermproject:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]prermproject[/green]"

prermvirtualenv:
    #!/usr/bin/env sh
    uvx --quiet rich --print "[green]prermvirtualenv[/green]"
