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

# Base config dir for these scripts. Honors XDG_CONFIG_HOME (falling back to
# ~/.config), and deliberately uses its own `cmux-tmux` subdir rather than
# `cmux`: that directory belongs to the cmux app (cmux.json, settings.json),
# so keeping our files apart avoids collisions and lets this dir be managed
# independently.
def config_home() -> Path:
    xdg = os.environ.get("XDG_CONFIG_HOME")
    return Path(xdg) if xdg else Path.home() / ".config"


CONFIG_DIR = config_home() / "cmux-tmux"
DEFAULT_TOML = CONFIG_DIR / "session-dump.toml"
DEFAULT_JSON = CONFIG_DIR / "session-dump.json"

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


def write_atomic(path: Path, content: str) -> None:
    """Replace a file's contents in one step.

    These files hold hand-edited data that cannot be recovered from cmux or
    from tmux, so a half-written file after an interrupt is worse than no
    write at all. os.replace is atomic within a filesystem and still works
    when the tmp file lands on a different one.
    """
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(content)
    os.replace(tmp, path)


def save_dump(path: Path, workspaces: list["Workspace"], use_toml: bool = True) -> None:
    """Write a dump file. The counterpart to load_dump()."""
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

    write_atomic(path, content)


def local_hostnames() -> set[str]:
    hostname = socket.gethostname()
    return {hostname.lower(), hostname.split(".")[0].lower()}


# Machine list lives in config, not code, so adding a Mac does not mean
# editing a script. Kept alongside the session dump in CONFIG_DIR.
HOSTS_TOML = CONFIG_DIR / "hosts.toml"

# Legacy locations, from before these files were consolidated under
# CONFIG_DIR. migrate_legacy_config() relocates any that still exist so the
# move happens automatically on each machine the dotfiles sync to.
_LEGACY_PATHS = {
    config_home() / "cmux" / "session-dump.toml": DEFAULT_TOML,
    config_home() / "cmux" / "session-dump.json": DEFAULT_JSON,
    config_home() / "tmux" / "hosts.toml": HOSTS_TOML,
}


def migrate_legacy_config() -> None:
    """Move config from its pre-consolidation paths into CONFIG_DIR, once.

    Idempotent and safe: only moves a legacy file when the new location does
    not already exist, so a machine that has already migrated (or been set up
    fresh) is untouched. Best-effort -- a move that fails (e.g. permissions)
    is left for the reader guards to handle rather than crashing a script.
    """
    to_move = {
        old: new
        for old, new in _LEGACY_PATHS.items()
        if old.is_file() and not new.exists()
    }
    if not to_move:
        return
    CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    for old, new in to_move.items():
        try:
            os.replace(old, new)
        except OSError:
            pass


# Run once when any cmux-* script imports this module, so the relocation
# happens transparently on every machine the dotfiles reach.
migrate_legacy_config()

_hosts_cache: dict | None = None


def _load_hosts() -> dict:
    """Parse hosts.toml once per process.

    Missing file is not an error here -- an explicit --host still works
    without one. Callers that need the list raise their own error.
    """
    global _hosts_cache
    if _hosts_cache is None:
        if HOSTS_TOML.is_file():
            _hosts_cache = tomllib.loads(HOSTS_TOML.read_text())
        else:
            _hosts_cache = {}
    return _hosts_cache


def default_hosts() -> list[str]:
    """Hosts to act on when none were named on the command line.

    $TMUX_REMOTE_HOSTS (space separated) wins over the config file, so a
    one-off run can target a different set without editing anything.
    """
    override = os.environ.get("TMUX_REMOTE_HOSTS", "").strip()
    if override:
        return shlex.split(override)

    hosts = _load_hosts().get("hosts", [])
    if not hosts:
        raise RuntimeError(
            f"No hosts configured. Add a `hosts = [...]` list to {HOSTS_TOML}, "
            f"or pass --host explicitly."
        )
    return hosts


def host_aliases() -> dict[str, str]:
    """ssh name -> that machine's own hostname, where the two differ."""
    return _load_hosts().get("aliases", {})


def is_local_host(host: str) -> bool:
    """True when `host` names the machine we are running on."""
    names = {host.lower()}
    alias = host_aliases().get(host)
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
