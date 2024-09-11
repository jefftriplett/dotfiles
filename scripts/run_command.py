# KUDOS to: https://github.com/hugovk/pypistats/blob/main/scripts/run_command.py

import subprocess


def run(command: str, with_console: bool = True) -> None:
    output = subprocess.run(command.split(), capture_output=True, text=True)

    print()

    if with_console:
        print("```shell")
        print(f"$ {command}\n")

    print(output.stdout.strip())

    if with_console:
        print("```")

    print()
