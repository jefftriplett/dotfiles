"""Shared model and helpers for the cmux-* scripts.

Used by cmux-dump-save, cmux-dump-restore, cmux-dump-edit, cmux-tmux-sync,
and cmux-tmux-watch, plus tmux-remote-ls for its session parsing.

Not a standalone script: those uv scripts import it, and find it because Python
puts the script's own directory on sys.path.
"""

import json
import os
import shlex
import socket
import subprocess
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
    """Read a dump file; format detected by extension (.json, else TOML).

    Accepts either a bare list of workspaces or a {"workspaces": [...]}
    wrapper in both formats, so hand-written files match either style.
    """
    if path.suffix == ".json":
        data = json.loads(path.read_text())
    else:
        data = tomllib.loads(path.read_text())
    if isinstance(data, dict):
        return data["workspaces"]
    return data


def save_dump(path: Path, workspaces: list["Workspace"], use_toml: bool = True) -> None:
    """Write a dump file atomically. The counterpart to load_dump().

    Atomic because the file holds hand-edited fields: an interrupted write
    would lose annotations that cannot be recovered from cmux. os.replace
    also works when the tmp file lands on a different filesystem.
    """
    # Imported here, not at module scope: only cmux-dump-save declares
    # tomli-w in its uv header, and a top-level import would break every
    # other script that imports this module.
    import tomli_w

    if use_toml:
        # TOML has no null; drop empty/default fields instead
        cleaned = [ws.to_dict(compact=True) for ws in workspaces]
        content = tomli_w.dumps({"workspaces": cleaned})
    else:
        content = json.dumps([ws.to_dict() for ws in workspaces], indent=2) + "\n"

    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(content)
    os.replace(tmp, path)


def local_hostnames() -> set[str]:
    hostname = socket.gethostname()
    return {hostname.lower(), hostname.split(".")[0].lower()}


# The Macs. Names must be resolvable by ssh (Tailscale MagicDNS or
# ~/.ssh/config). Edit when a machine joins or leaves.
DEFAULT_HOSTS = [
    "mac-mini-pro-2023",
    "mac-studio-2023",
    "mba-2025",
]

# ssh name -> that machine's own `hostname`, for hosts where the two differ.
# Without this, running on the Air (hostname MacBook-Air-2025) would not
# recognize "mba-2025" as itself and would try to reach its own address.
HOST_ALIASES = {
    "mba-2025": "MacBook-Air-2025",
}


def is_local_host(host: str) -> bool:
    """True when `host` names the machine we are running on."""
    names = {host.lower()}
    alias = HOST_ALIASES.get(host)
    if alias:
        names.add(alias.lower())
    return bool(names & local_hostnames())


@dataclass
class Workspace:
    title: str
    cwd: str
    color: str | None = None
    pinned: bool = False
    description: str | None = None
    host: str | None = None
    tmux: bool = False
    session: str | None = None

    @classmethod
    def from_cmux(cls, ws: dict) -> "Workspace":
        # .get() throughout: cmux's --json schema may drift, and a missing
        # key should degrade to the default rather than crash with KeyError
        try:
            title = ws["title"]
            cwd = ws["current_directory"]
        except KeyError as exc:
            raise RuntimeError(
                f"cmux workspace entry missing required key {exc}: {ws!r}"
            ) from exc
        return cls(
            title=strip_mosh_prefix(title),
            cwd=cwd,
            color=ws.get("custom_color"),
            pinned=ws.get("pinned", False),
            description=ws.get("description"),
        )

    @classmethod
    def from_dump(cls, ws: dict) -> "Workspace":
        return cls(
            title=ws["title"],
            cwd=ws["cwd"],
            color=ws.get("color"),
            pinned=ws.get("pinned", False),
            description=ws.get("description"),
            # "machine" is the pre-rename spelling of "host". Still read so
            # hand-edited dump files keep working; cmux-dump-save rewrites the
            # key as "host" the next time it runs.
            host=ws.get("host", ws.get("machine")),
            tmux=ws.get("tmux", False),
            session=ws.get("session"),
        )

    @property
    def annotated(self) -> bool:
        return bool(self.host) or self.tmux or bool(self.session)

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
        # An explicit `session` is already a valid tmux session name and is
        # used verbatim (tmux allows spaces; slugifying it would attach a
        # different session). Title-derived names are slugified because tmux
        # session names may not contain ":" or ".". Built from the base title
        # (not display_title), so the "[mosh] " label and its slugified form
        # never reach the remote tmux. Keep the replacement set in sync with
        # __tmux_session_name in ~/.bash_tmux.
        if self.session:
            return self.session
        return self.base_title.replace(":", "-").replace(".", "-").replace(" ", "-")

    @property
    def is_remote(self) -> bool:
        # is_local_host, not local_hostnames: the ssh name and the machine's
        # own hostname differ (mba-2025 vs MacBook-Air-2025), and only
        # is_local_host consults HOST_ALIASES to bridge them. Comparing
        # against local_hostnames alone would call this Mac remote and try to
        # mosh into itself.
        return bool(self.host) and not is_local_host(self.host)

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
                    f"mosh {shlex.quote(self.host)} --"
                    f" sh -c {shlex.quote(shell_command)}"
                )
            return f"mosh {shlex.quote(self.host)}"

        if self.tmux:
            return shell_command

        return None


# Fields requested from `tmux list-sessions -F`, in the order parse_sessions
# expects them. Shared so local and remote callers stay in lockstep.
SESSION_FORMAT = (
    "#{session_name}\t#{session_attached}\t#{session_path}\t#{session_windows}"
)


@dataclass
class TmuxSession:
    name: str
    attached: int
    path: str
    windows: int = 0

    @property
    def is_attached(self) -> bool:
        return self.attached > 0


def parse_sessions(stdout: str) -> list[TmuxSession]:
    """Parse `tmux list-sessions -F SESSION_FORMAT` output."""
    sessions = []
    for line in stdout.splitlines():
        if not line.strip():
            continue
        name, attached, path, windows = line.split("\t")
        sessions.append(
            TmuxSession(
                name=name,
                attached=int(attached),
                path=path,
                windows=int(windows),
            )
        )
    return sessions


def cmux(*args: str) -> str:
    result = subprocess.run(
        ["cmux", *args],
        capture_output=True,
        text=True,
        check=True,
    )
    return result.stdout.strip()


def cmux_workspaces() -> list[Workspace]:
    entries = json.loads(cmux("workspace", "list", "--json"))["workspaces"]
    return [Workspace.from_cmux(entry) for entry in entries]


def tmux_sessions() -> list[TmuxSession]:
    """Running tmux sessions, newest server state. Empty when no server runs."""
    result = subprocess.run(
        ["tmux", "list-sessions", "-F", SESSION_FORMAT],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        # "no server running on ..." is the normal no-sessions case, not an error
        if "no server running" in result.stderr:
            return []
        raise RuntimeError(f"tmux list-sessions failed: {result.stderr.strip()}")

    return parse_sessions(result.stdout)


def remote_tmux_sessions(host: str, timeout: int = 5) -> list[TmuxSession]:
    """Sessions on a remote host, over ssh. Empty when no server runs there.

    ssh rather than mosh: this is a one-shot non-interactive command, matching
    what tmux-ls and tmux-kill do. BatchMode means a host that would prompt
    fails fast instead of hanging.
    """
    # bash -lc so the login profile puts Homebrew's tmux on PATH; the remote
    # shell re-parses, so the tmux command is quoted as a single word.
    tmux_command = shlex.join(["tmux", "list-sessions", "-F", SESSION_FORMAT])
    result = subprocess.run(
        [
            "ssh",
            "-o", "BatchMode=yes",
            "-o", f"ConnectTimeout={timeout}",
            host,
            f"bash -lc {shlex.quote(tmux_command)}",
        ],
        capture_output=True,
        text=True,
        # Guard against an ssh that connects but then never returns; the
        # ConnectTimeout above only covers establishing the connection.
        timeout=timeout * 4,
    )
    if result.returncode != 0:
        if "no server running" in result.stderr:
            return []
        raise RuntimeError(result.stderr.strip() or f"ssh exited {result.returncode}")
    return parse_sessions(result.stdout)


def workspace_action(ref: str, action: str, *extra: str) -> None:
    cmux("workspace-action", "--action", action, "--workspace", ref, *extra)


def create_workspace(ws: Workspace) -> str:
    command = ws.command()

    # When we issue our own launch command (mosh and/or tmux), open the local
    # pane in a neutral dir. Otherwise the shell's tmux autoattach -- triggered
    # by a project .envrc (`use tmux`) -- execs a local tmux session before our
    # command runs, and the mosh/tmux command ends up nested inside it. The
    # command's own `cd` sets the real working directory. Plain workspaces keep
    # their cwd so their normal .envrc autoattach behaves as usual.
    local_cwd = str(Path.home()) if command else ws.cwd
    create_args = [
        "workspace", "create",
        "--name", ws.display_title,
        "--cwd", local_cwd,
        "--focus", "false",
    ]

    if command:
        create_args += ["--command", command]

    output = cmux(*create_args)
    ref = output.split()[-1]
    if not ref.startswith("workspace:"):
        raise RuntimeError(
            f"Unexpected cmux output creating {ws.display_title!r}: {output!r}"
        )
    if ws.color:
        workspace_action(ref, "set-color", "--color", ws.color)
    if ws.pinned:
        workspace_action(ref, "pin")
    if ws.description:
        workspace_action(ref, "set-description", "--description", ws.description)
    return ref
