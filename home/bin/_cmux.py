"""Shared model and helpers for cmux-dump / cmux-restore / cmux-open.

Not a standalone script: the cmux-* uv scripts import it, and find it because
Python puts the script's own directory on sys.path.
"""

import json
import shlex
import socket
import tomllib
from dataclasses import asdict, dataclass
from pathlib import Path

DEFAULT_DIR = Path.home() / ".config" / "cmux"
DEFAULT_TOML = DEFAULT_DIR / "session-dump.toml"
DEFAULT_JSON = DEFAULT_DIR / "session-dump.json"

# Label prefixed onto the cmux workspace title for remote (mosh) workspaces.
# It is display-only: the remote tmux session name is derived from the base
# title (or `session`), so the prefix never reaches the remote host.
MOSH_PREFIX = "[mosh] "


def strip_mosh_prefix(title: str) -> str:
    while title.startswith(MOSH_PREFIX):
        title = title[len(MOSH_PREFIX):]
    return title


def default_dump_path() -> Path:
    """Prefer the TOML dump; fall back to JSON only if the TOML is absent."""
    return DEFAULT_TOML if DEFAULT_TOML.is_file() else DEFAULT_JSON


def load_dump(path: Path) -> list[dict]:
    """Read a dump file; format detected by extension (.json, else TOML)."""
    if path.suffix == ".json":
        return json.loads(path.read_text())
    return tomllib.loads(path.read_text())["workspaces"]


def local_hostnames() -> set[str]:
    hostname = socket.gethostname()
    return {hostname.lower(), hostname.split(".")[0].lower()}


@dataclass
class Workspace:
    title: str
    cwd: str
    color: str | None = None
    pinned: bool = False
    description: str | None = None
    machine: str | None = None
    tmux: bool = False
    session: str | None = None

    @classmethod
    def from_cmux(cls, ws: dict) -> "Workspace":
        return cls(
            title=strip_mosh_prefix(ws["title"]),
            cwd=ws["current_directory"],
            color=ws["custom_color"],
            pinned=ws["pinned"],
            description=ws["description"],
        )

    @classmethod
    def from_dump(cls, ws: dict) -> "Workspace":
        return cls(
            title=ws["title"],
            cwd=ws["cwd"],
            color=ws.get("color"),
            pinned=ws.get("pinned", False),
            description=ws.get("description"),
            machine=ws.get("machine"),
            tmux=ws.get("tmux", False),
            session=ws.get("session"),
        )

    @property
    def annotated(self) -> bool:
        return bool(self.machine) or self.tmux or bool(self.session)

    def to_dict(self, compact: bool = False) -> dict:
        data = asdict(self)
        if compact:
            return {
                key: value
                for key, value in data.items()
                if value is not None and value is not False
            }
        return data

    @property
    def base_title(self) -> str:
        # The title without the display-only "[mosh] " label, so the prefix is
        # never doubled and never leaks into the tmux session name.
        return strip_mosh_prefix(self.title)

    @property
    def display_title(self) -> str:
        # cmux workspace title: remote workspaces get the "[mosh] " label.
        if self.is_remote:
            return f"{MOSH_PREFIX}{self.base_title}"
        return self.base_title

    @property
    def session_name(self) -> str:
        # An explicit `session` overrides the title-derived name. Built from the
        # base title (not display_title), so the "[mosh] " label and its
        # slugified form never reach the remote tmux. tmux session names may
        # not contain ":" or ".". Keep the replacement set in sync with
        # __tmux_session_name in ~/.bash_tmux.
        name = self.session or self.base_title
        return name.replace(":", "-").replace(".", "-").replace(" ", "-")

    @property
    def is_remote(self) -> bool:
        return bool(self.machine) and self.machine.lower() not in local_hostnames()

    def command(self) -> str | None:
        cwd = shlex.quote(self.cwd)
        tmux_command = (
            f"tmux new-session -A -s {shlex.quote(self.session_name)} -c {cwd}"
        )
        # cd first so a freshly created session lands in cwd even if tmux's
        # -c is bypassed; ";" (not "&&") so attaching to an existing session
        # still works when the directory is missing on the remote
        shell_command = f"cd {cwd}; {tmux_command}"

        if self.is_remote:
            if self.tmux:
                # mosh passes the command to mosh-server as a clean argv and
                # execs it directly (no remote login shell re-parse), so the
                # command is quoted once, only for the local cmux-pane shell.
                # The "--" stops mosh parsing "-c" as its own option.
                return (
                    f"mosh {shlex.quote(self.machine)} --"
                    f" sh -c {shlex.quote(shell_command)}"
                )
            return f"mosh {shlex.quote(self.machine)}"

        if self.tmux:
            return shell_command

        return None
