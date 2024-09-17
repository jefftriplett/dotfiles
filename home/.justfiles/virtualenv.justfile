# ----------------------------------------------------------------
# virtualenv recipes - https://virtualenv.pypa.io/en/latest/
# ----------------------------------------------------------------

justfile := justfile_directory() + "/.justfiles/virtualenv.justfile"

[private]
@default:
    just --list --justfile {{ justfile }}

[private]
@fmt:
    just --fmt --justfile {{ justfile }}

scan:
    #!/usr/bin/env python
    import subprocess
    from pathlib import Path

    folders = [folder for folder in Path(Path.home(), ".virtualenvs").glob("*/bin/python")]
    # print(len(folders))
    for command in folders:
        # print(command)
        try:
            # grab python version
            output = subprocess.run(f"{command} --version".split(), capture_output=True, text=True)
            print(output.stdout.strip() or output.stderr.strip())

            # grab pip version
            # output = subprocess.run(f"{command} --version".replace("python", "pip").split(), capture_output=True, text=True)
            # print(output.stdout.strip() or output.stderr.strip())

        except FileNotFoundError as e:
            pass

@upgrade:
    for filename in $(ls -d ~/.virtualenvs/*/); do \
        echo "$filename"; \
        $filename/bin/python --version; \
        $filename/bin/python -m pip --version; \
        $filename/bin/python -m pip install --upgrade pip; \
        echo; \
    done

    # TODO: finish researching this pattern...
    # https://stackoverflow.com/questions/44692668/python-how-can-i-update-python-version-in-pyenv-virtual-environment

    # pip freeze > requirements.lock
    # pyenv delete a-name
    # pyenv virtualenv 3.9.0 a-name
    # pip install -r requirements.lock
    # rm requirements.lock

@workon:
    for filename in $(ls -d ~/.virtualenvs/*/); do \
        echo "$filename"; \
        $filename/bin/python --version; \
        $filename/bin/python -m pip --version; \
        echo; \
    done
