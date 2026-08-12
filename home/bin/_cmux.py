"""Shared model and helpers for the cmux-* scripts.

Used by cmux-dump-save, cmux-dump-restore, cmux-dump-edit, cmux-tmux-sync,
and cmux-tmux-watch, plus tmux-remote-ls for its session parsing.

Not a standalone script: those uv scripts import it, and find it because Python
puts the script's own directory on sys.path.
"""

import json
import os
import shlex
import shutil
import socket
import subprocess
import tomllib
from dataclasses import asdict, dataclass
from pathlib import Path


def require(binary: str, *, reason: str = "") -> None:
    """Fail early and clearly when a required command is missing.

    The remote/tmux launch commands run inside a cmux pane where their failure
    is invisible to us, so it is better to refuse up front than to create a
    workspace whose command silently dies.
    """
    if shutil.which(binary) is None:
        hint = f" ({reason})" if reason else ""
        raise RuntimeError(f"required command not found: {binary}{hint}")

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


def session_slug(name: str) -> str:
    """Make `name` usable as a tmux session name.

    tmux session names may not contain ":" or "."; spaces are legal but a
    nuisance to type at `tmux attach -t`. This is the single definition --
    _projects.py, __tmux_session_name in ~/.bash_tmux, and use_tmux in
    ~/.config/direnv/direnvrc all have to agree with it, or the same project
    resolves to two different sessions depending on which one you went through.
    """
    return name.replace(":", "-").replace(".", "-").replace(" ", "-")


def tmux_attach_command(session: str, path: str, *, tmux: bool = True) -> str:
    """The shell command that lands you in `path`, in a tmux session or not.

    The single definition of "open this project here". Every caller wraps it
    differently -- cmux needs a command string for a pane, workon needs an argv
    to exec, one goes through `sh -c` and the other `bash -lc` -- but the thing
    being wrapped has to be identical, or the same project opens two different
    ways depending on which door you came through. That drift is exactly what
    this is here to prevent.

    `path` arrives already quoted (or as a "$HOME"/... expression that has to
    expand on the far side), so it is interpolated rather than re-quoted.

    cd first, so a freshly created session lands in the right place even when
    tmux's -c is bypassed; ";" and not "&&", so attaching to an existing
    session still works when the directory is missing on the other machine.
    """
    if not tmux:
        return f"cd {path}; exec bash -l"
    return f"cd {path}; tmux new-session -A -s {shlex.quote(session)} -c {path}"


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


def load_groups(path: Path) -> list[dict]:
    """Read the `groups` section of a dump, or [] when absent.

    A bare-list dump (the old workspaces-only format) has no groups, so this
    returns [] and restore just skips group reconstruction.
    """
    if path.suffix == ".json":
        data = json.loads(path.read_text())
    else:
        data = tomllib.loads(path.read_text())
    if isinstance(data, dict):
        return data.get("groups", [])
    return []


def write_atomic(path: Path, *, content: str) -> None:
    """Replace a file's contents in one step.

    These files hold hand-edited data that cannot be recovered from cmux or
    from tmux, so a half-written file after an interrupt is worse than no
    write at all. os.replace is atomic within a filesystem and still works
    when the tmp file lands on a different one.
    """
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(content)
    os.replace(tmp, path)


def save_dump(
    path: Path,
    *,
    workspaces: list["Workspace"],
    groups: list["Group"] | None = None,
    use_toml: bool = True,
) -> None:
    """Write a dump file. The counterpart to load_dump()/load_groups()."""
    # Imported here, not at module scope: only cmux-dump-save declares
    # tomli-w in its uv header, and a top-level import would break every
    # other script that imports this module.
    import tomli_w

    if use_toml:
        # TOML has no null; drop empty/default fields instead
        document: dict = {"workspaces": [ws.to_dict(compact=True) for ws in workspaces]}
        if groups:
            document["groups"] = [g.to_dict(compact=True) for g in groups]
        content = tomli_w.dumps(document)
    else:
        content = json.dumps([ws.to_dict() for ws in workspaces], indent=2) + "\n"

    write_atomic(path, content=content)


def local_hostnames() -> set[str]:
    hostname = socket.gethostname()
    return {hostname.lower(), hostname.split(".")[0].lower()}


# Machine list lives in config, not code, so adding a Mac does not mean
# editing a script. Kept alongside the session dump in CONFIG_DIR.
#
# hosts.toml is now the fallback: the machine list moved into the [machines]
# table of the project registry (~/Projects/projects.toml) so a machine is
# named in one place rather than two. hosts.toml is still read when the
# registry has no [machines] table, which keeps every cmux-*/tmux-remote-*
# script working on a Mac the registry has not reached yet.
HOSTS_TOML = CONFIG_DIR / "hosts.toml"


def registry_toml() -> Path:
    """Path to the project registry. Mirrors _projects.registry_path().

    Duplicated rather than imported: _projects imports this module, so reaching
    the other way would be a cycle. It is one path and two env lookups.
    """
    override = os.environ.get("PROJECTS_TOML", "").strip()
    if override:
        return Path(override).expanduser()
    return Path.home() / "Projects" / "projects.toml"


def _registry_machines() -> dict:
    """The [machines] table from the registry, or {} if there isn't one."""
    path = registry_toml()
    if not path.is_file():
        return {}
    try:
        return tomllib.loads(path.read_text()).get("machines", {})
    except (tomllib.TOMLDecodeError, OSError):
        # A registry mid-edit should not take down `tmux-remote-ls`; fall
        # through to hosts.toml and let the `projects` CLI report the error.
        return {}

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

    machines = _registry_machines()
    if machines:
        return sorted(
            entry.get("host", key) for key, entry in machines.items()
        )

    hosts = _load_hosts().get("hosts", [])
    if not hosts:
        raise RuntimeError(
            f"No hosts configured. Add a [machines] table to {registry_toml()} "
            f"(see `projects machines add`), or pass --host explicitly."
        )
    return hosts


def host_aliases() -> dict[str, str]:
    """ssh name -> that machine's own hostname, where the two differ."""
    machines = _registry_machines()
    if machines:
        return {
            entry.get("host", key): entry["hostname"]
            for key, entry in machines.items()
            if entry.get("hostname")
        }
    return _load_hosts().get("aliases", {})


def resolve_host(name: str) -> str:
    """Turn a registry machine key into its ssh name; pass anything else through.

    Lets `--host mini` work the same as `--host mac-mini-pro-2023`, so the short
    names used in projects.toml are usable everywhere a host is accepted.
    """
    machines = _registry_machines()
    entry = machines.get(name)
    if entry:
        return entry.get("host", name)
    return name


def is_local_host(host: str) -> bool:
    """True when `host` names the machine we are running on."""
    host = resolve_host(host)
    names = {host.lower(), host.split(".")[0].lower()}
    alias = host_aliases().get(host)
    if alias:
        names |= {alias.lower(), alias.split(".")[0].lower()}
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
        return session_slug(self.base_title)

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
        # Shared with workon via _projects.py, so a pane cmux restores and a
        # project workon opens land identically. See tmux_attach_command.
        shell_command = tmux_attach_command(self.session_name, cwd)

        if self.is_remote:
            require("mosh", reason=f"needed to reach {self.host}")
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


@dataclass
class Group:
    """A cmux sidebar group, keyed by workspace *titles* rather than refs.

    cmux identifies group members by ref (workspace:N), but refs are assigned
    fresh every time a workspace is created, so they mean nothing across a
    dump/restore. Titles are the dump's stable key everywhere else, so groups
    use them too: save resolves refs -> titles, restore resolves titles ->
    the newly created refs.
    """

    name: str
    anchor: str          # title of the anchor (owner) workspace
    members: list[str]   # member workspace titles, anchor included
    pinned: bool = False
    collapsed: bool = False
    color: str | None = None
    icon: str | None = None

    @classmethod
    def from_dump(cls, data: dict) -> "Group":
        return cls(
            name=data["name"],
            anchor=data["anchor"],
            members=list(data.get("members", [])),
            pinned=data.get("pinned", False),
            collapsed=data.get("collapsed", False),
            color=data.get("color"),
            icon=data.get("icon"),
        )

    def to_dict(self, *, compact: bool = False) -> dict:
        data = asdict(self)
        if compact:
            return {
                key: value
                for key, value in data.items()
                if value is not None and value is not False
            }
        return data


# Fields requested from `tmux list-sessions -F`, in the order parse_sessions
# expects them. Shared so local and remote callers stay in lockstep.
#
# Fields are joined with US (unit separator, \x1f) rather than a tab: a
# session name or path may legitimately contain a tab, which would misalign a
# tab-split, but no tmux name or filesystem path contains a control char, so
# \x1f is an unambiguous delimiter.
SESSION_DELIM = "\x1f"
SESSION_FORMAT = SESSION_DELIM.join(
    (
        "#{session_name}",
        "#{session_attached}",
        "#{session_path}",
        "#{session_windows}",
    )
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
    """Parse `tmux list-sessions -F SESSION_FORMAT` output.

    Lines that don't split into the expected fields are skipped rather than
    raising: a remote `bash -lc` may interleave login-profile chatter with the
    real output, and one noisy line shouldn't abort the whole listing.
    """
    sessions = []
    for line in stdout.splitlines():
        if not line.strip():
            continue
        parts = line.split(SESSION_DELIM)
        if len(parts) != 4:
            continue
        name, attached, path, windows = parts
        try:
            sessions.append(
                TmuxSession(
                    name=name,
                    attached=int(attached),
                    path=path,
                    windows=int(windows),
                )
            )
        except ValueError:
            # attached/windows weren't integers -- not a real session line
            continue
    return sessions


def cmux(*args: str) -> str:
    try:
        result = subprocess.run(
            ["cmux", *args],
            capture_output=True,
            text=True,
            check=True,
        )
    except FileNotFoundError:
        raise RuntimeError(
            "required command not found: cmux (is the cmux app installed and on PATH?)"
        )
    return result.stdout.strip()


def cmux_workspaces() -> list[Workspace]:
    entries = json.loads(cmux("workspace", "list", "--json"))["workspaces"]
    return [Workspace.from_cmux(entry) for entry in entries]


def _ref_title_map() -> dict[str, str]:
    """ref (workspace:N) -> base title, for joining group members to titles."""
    entries = json.loads(cmux("workspace", "list", "--json"))["workspaces"]
    return {entry["ref"]: strip_mosh_prefix(entry["title"]) for entry in entries}


def title_ref_map() -> dict[str, str]:
    """Base title -> ref, for turning dumped group members back into refs.

    Titles are not guaranteed unique; the last workspace with a given title
    wins. Callers that create the workspaces first (restore) then read this map
    get the freshly created refs.
    """
    return {title: ref for ref, title in _ref_title_map().items()}


def cmux_groups() -> list[Group]:
    """Current sidebar groups, with members expressed as titles."""
    ref_title = _ref_title_map()
    groups = json.loads(cmux("workspace-group", "list", "--json"))["groups"]
    result = []
    for g in groups:
        members = [
            ref_title[r] for r in g.get("member_workspace_refs", []) if r in ref_title
        ]
        anchor_ref = g.get("anchor_workspace_ref")
        anchor = ref_title.get(anchor_ref, members[0] if members else "")
        result.append(
            Group(
                name=g["name"],
                anchor=anchor,
                members=members,
                pinned=g.get("is_pinned", False),
                collapsed=g.get("is_collapsed", False),
                color=g.get("custom_color"),
                icon=g.get("icon_symbol"),
            )
        )
    return result


def _group_raw(group_ref: str) -> dict:
    groups = json.loads(cmux("workspace-group", "list", "--json"))["groups"]
    for g in groups:
        if g["ref"] == group_ref:
            return g
    return {}


def create_group(group: Group, *, refs_by_title: dict[str, str]) -> str | None:
    """Recreate a group from a dump. Returns its ref, or None if unbuildable.

    Members whose titles no longer resolve to a workspace are skipped; a group
    with no resolvable members is not created at all.

    `cmux workspace-group create` always spawns a fresh anchor workspace (its
    header) titled after the group, in addition to the members passed via
    --from. The original anchor in a dump is a real workspace, though, so we
    re-anchor the group onto it and close *only that one* auto-created header --
    identified as the group's anchor ref right after creation, never by
    guessing from the member list, so a real member can't be closed by mistake.
    Closing happens only after set-anchor, since closing a group's current
    anchor would dissolve the whole group.
    """
    member_refs = [
        refs_by_title[title] for title in group.members if title in refs_by_title
    ]
    if not member_refs:
        return None

    output = cmux(
        "workspace-group", "create",
        "--name", group.name,
        "--from", ",".join(member_refs),
    )
    ref = output.split()[-1]
    if not ref.startswith("workspace_group:"):
        raise RuntimeError(
            f"Unexpected cmux output creating group {group.name!r}: {output!r}"
        )

    # The header cmux just created is now the group's anchor; it is a stray
    # only when it isn't one of the workspaces we asked to include.
    auto_anchor = _group_raw(ref).get("anchor_workspace_ref")
    stray = auto_anchor if auto_anchor and auto_anchor not in member_refs else None

    anchor_ref = refs_by_title.get(group.anchor)
    if anchor_ref and anchor_ref in member_refs:
        cmux("workspace-group", "set-anchor", "--group", ref, "--workspace", anchor_ref)
        if stray:  # safe now that the real anchor owns the group
            cmux("workspace", "close", "--workspace", stray)
    # else: no dumped anchor resolved; keep cmux's header rather than risk
    # dissolving the group by closing the only anchor it has.

    if group.color:
        cmux("workspace-group", "set-color", ref, "--hex", group.color)
    if group.icon:
        cmux("workspace-group", "set-icon", ref, "--symbol", group.icon)
    if group.collapsed:
        cmux("workspace-group", "collapse", ref)
    if group.pinned:
        cmux("workspace-group", "pin", ref)
    return ref


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


def remote_tmux_sessions(host: str, *, timeout: int = 5) -> list[TmuxSession]:
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


def remote_tmux_sessions_via_rpc(
    host: str, *, timeout: int = 10
) -> tuple[list[TmuxSession] | None, str | None]:
    """Sessions on `host`, via cmux's `remote.tmux.sessions` rpc.

    Returns (sessions, None) on success, or (None, reason) on any failure --
    cmux missing, host unreachable, the remote-tmux beta flag off for this
    account. Callers fall back to the ssh path in remote_tmux_sessions() on
    None; `reason` is carried along only for callers that want to report why
    (e.g. tmux-remote-ls's --json output), not for control flow.

    No `path` (cwd) in the result: the rpc method does not report a session's
    working directory the way `tmux list-sessions -F` does. Fine for
    tmux-remote-ls's read-only listing; cmux-tmux-sync needs the real cwd to
    open a workspace in the right place, so it keeps using
    remote_tmux_sessions()'s ssh path instead of this one.
    """
    try:
        result = subprocess.run(
            ["cmux", "rpc", "remote.tmux.sessions", json.dumps({"host": host})],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except FileNotFoundError:
        return None, "cmux not found on PATH"
    except subprocess.TimeoutExpired:
        return None, f"rpc timed out after {timeout}s"
    if result.returncode != 0:
        reason = result.stderr.strip() or f"cmux rpc exited {result.returncode}"
        return None, reason
    try:
        data = json.loads(result.stdout)
    except json.JSONDecodeError:
        return None, "cmux rpc returned invalid JSON"

    sessions = []
    for entry in data.get("sessions", []):
        try:
            sessions.append(
                TmuxSession(
                    name=entry["name"],
                    attached=1 if entry.get("attached") else 0,
                    path="",
                    windows=entry.get("windows", 0),
                )
            )
        except KeyError:
            continue
    return sessions, None


def kill_tmux_session(name: str, *, host: str | None = None, timeout: int = 5) -> None:
    """Kill one tmux session, here or on `host`. Raises RuntimeError on failure.

    Mirrors the session readers above: the same ssh shape, the same bash -lc so
    the login profile puts Homebrew's tmux on PATH, and the same treatment of a
    dead server. "-t=name" rather than "-t name" because tmux's target syntax
    matches a bare -t as a prefix -- `-t agents` would happily kill
    "agents-scratch" if "agents" itself had already gone away, which is not a
    thing to discover after the fact.
    """
    tmux_command = ["tmux", "kill-session", f"-t={name}"]
    if host is None:
        argv = tmux_command
        run_timeout = None
    else:
        argv = [
            "ssh",
            "-o", "BatchMode=yes",
            "-o", f"ConnectTimeout={timeout}",
            host,
            f"bash -lc {shlex.quote(shlex.join(tmux_command))}",
        ]
        run_timeout = timeout * 4

    result = subprocess.run(argv, capture_output=True, text=True, timeout=run_timeout)
    if result.returncode != 0:
        message = result.stderr.strip() or f"exited {result.returncode}"
        raise RuntimeError(message)


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
