#!/bin/sh
SUBCOMMAND=pip-$1.py;

if [ -f "$VIRTUAL_ENV/bin/pip" ]; then
  ORIGINAL_COMMAND=$VIRTUAL_ENV/bin/pip
else
  ORIGINAL_COMMAND=/usr/local/bin/pip
fi

command -v $SUBCOMMAND >/dev/null 2>&1 || {
    exec $ORIGINAL_COMMAND $*;
    exit 1;
}

exec pip-$*.py;
exit 1;
