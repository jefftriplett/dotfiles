# ----------------------------------------------------------------
# virtualenvwrapper
# ----------------------------------------------------------------

_get_env_details:
    #!/usr/bin/env sh
    rich --print "[green]get_env_details[/green]"

_initialize:
    #!/usr/bin/env sh
    rich --print "[green]initialize[/green]"

_postactivate:
    #!/usr/bin/env sh
    VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    rich --print "[green]postactivate[/green]"

_postdeactivate:
    #!/usr/bin/env sh
    # VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    rich --print "[green]postdeactivate[/green]"

_postmkproject:
    #!/usr/bin/env sh
    rich --print "[green]postmkproject[/green]"

_postmkvirtualenv:
    #!/usr/bin/env sh
    rich --print "[green]postmkvirtualenv[/green]"
    python -m pip install --upgrade pip
    python -m pip install --upgrade pip-tools
    python -m pip install --upgrade uv

_postrmproject:
    #!/usr/bin/env sh
    rich --print "[green]postrmproject[/green]"

_postrmvirtualenv:
    #!/usr/bin/env sh
    rich --print "[green]postrmvirtualenv[/green]"

_preactivate:
    #!/usr/bin/env sh
    # VIRTUAL_ENV_NAME=$(basename "${VIRTUAL_ENV}")
    rich --print "[green]preactivate[/green]"

_predeactivate:
    #!/usr/bin/env sh
    rich --print "[green]predeactivate[/green]"

_premkproject:
    #!/usr/bin/env sh
    rich --print "[green]premkproject[/green]"

_premkvirtualenv:
    #!/usr/bin/env sh
    rich --print "[green]premkvirtualenv[/green]"

_prermproject:
    #!/usr/bin/env sh
    rich --print "[green]prermproject[/green]"

_prermvirtualenv:
    #!/usr/bin/env sh
    rich --print "[green]prermvirtualenv[/green]"
