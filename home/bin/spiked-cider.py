import click
import json
import subprocess


def run_command(cmd, as_list=True):
    try:
        output = subprocess.check_output(
            cmd,
            stderr=subprocess.STDOUT,
            shell=True
        )
    except Exception as e:
        print 'Warning: {0}'.format(e)
        return []

    if as_list:
        lines = [line for line in output.split('\n') if line]
        return lines
    else:
        return output


def get_casks():
    casks = run_command('brew cask list')
    return casks or []


def get_formulas():
    formulas = run_command('brew list')
    return formulas or []


def get_taps():
    taps = run_command('brew tap')
    return taps or []


@click.command()
@click.option('--indent', default=4, help='JSON indentation length.')
def main(indent):
    doc = {
        'casks': get_casks(),
        'formulas': get_formulas(),
        'taps': get_taps(),
    }
    print json.dumps(doc, indent=indent)


if __name__ == '__main__':
    main()
