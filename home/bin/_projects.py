"""Shared model for the project registry in ~/Projects/projects.toml.

Used by the `projects` CLI and, through it, by the `workon` and `mkproject`
shell functions in ~/.bashrc.d/60-workon.bash.

The registry answers one question: given a project name, which machine is it
on, where does it live there, and what tmux session holds it. That was
previously spread across a project's .envrc (`use tmux NAME --machine X`), the
cmux session dump, and the directory scan in ~/.bashrc.d/60-workon.bash, so the same fact
had to be written three times and could disagree with itself.

Not a standalone script: the uv scripts in this directory import it, and find
it because Python puts the script's own directory on sys.path. Importing it
means declaring pydantic, which today only `projects` does. _cmux.py stays on
plain dataclasses for exactly that reason -- every cmux-* and tmux-remote-*
script imports it, and none of them should have to grow a dependency to do so.
"""

import os
import shlex
import shutil
import tomllib
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator

import fcntl
from pydantic import BaseModel, ConfigDict, Field, field_validator

from _cmux import local_hostnames, session_slug, tmux_attach_command

# The registry lives with the projects it tracks rather than in
# ~/.config/cmux-tmux/, so it is findable from a shell sitting in ~/Projects.
# $PROJECTS_TOML overrides it for a single run or for tests.
DEFAULT_REGISTRY = Path.home() / "Projects" / "projects.toml"

NEW_FILE_HEADER = """\
# Project registry: which machine each project lives on, and where.
#
# Read by `projects`, `workon`, and `mkproject`, and by the
# cmux-*/tmux-remote-* scripts for the machine list.
#
# [machines.<key>]  key is the short name you type; `host` must be resolvable
#                   by ssh (Tailscale MagicDNS or a ~/.ssh/config Host entry).
#                   `hostname` is that machine's own `hostname` output, needed
#                   only when it differs from the ssh name -- without it, the
#                   machine does not recognize itself and tries to mosh home.
#
# [defaults]        `tmux` toggles attaching a tmux session, and is off unless
#                   set -- a project gets one because it asked, not because it
#                   did not object. `home_dir` and `work_dir` are the roots new
#                   projects land under, which `--work` picks between. Nothing
#                   here names a machine: an owner is recorded from evidence or
#                   not at all.
#
# [projects.<key>]  `path` is the project directory. Everything else is
#                   optional: `machine` names a [machines] key, and leaving it
#                   out means the project is wherever you are -- which is the
#                   honest answer for a Syncthing-mirrored directory nobody has
#                   said otherwise about. `tmux_path` is the checkout inside it
#                   the session actually runs in, `tmux_session` the session
#                   name (defaults to the key), and `tmux` overrides [defaults].
"""


def registry_path() -> Path:
    override = os.environ.get("PROJECTS_TOML", "").strip()
    if not override:
        return DEFAULT_REGISTRY
    validate_path(override, field="PROJECTS_TOML")
    return Path(override).expanduser()


def validate_path(value: str, *, field: str) -> str:
    """Require portable registry paths, not cwd-relative surprises."""
    if not isinstance(value, str) or not value.strip():
        raise ValueError(f"{field} must not be empty")
    if value.startswith("~/") or Path(value).is_absolute():
        return value
    raise ValueError(f"{field} must be absolute or start with '~/' (got {value!r})")


@contextmanager
def registry_lock(path: Path) -> Iterator[None]:
    """Serialize a complete registry load-modify-save transaction."""
    path.parent.mkdir(parents=True, exist_ok=True)
    lock_path = path.with_name(f".{path.name}.lock")
    with lock_path.open("a+", encoding="utf-8") as lock:
        fcntl.flock(lock.fileno(), fcntl.LOCK_EX)
        try:
            yield
        finally:
            fcntl.flock(lock.fileno(), fcntl.LOCK_UN)


class Machine(BaseModel):
    model_config = ConfigDict(frozen=True)

    key: str
    host: str
    hostname: str | None = None

    @property
    def lookup_names(self) -> set[str]:
        """Every spelling that should resolve to this machine on the CLI."""
        return {self.key.lower(), self.host.lower(), self.host.split(".")[0].lower()}

    @property
    def local_names(self) -> set[str]:
        """Names this machine would call itself.

        Deliberately excludes `key`: a short key like "mini" is ours to choose
        and must not be matched against a hostname that merely looks like it.
        """
        names = {self.host.lower(), self.host.split(".")[0].lower()}
        if self.hostname:
            names |= {self.hostname.lower(), self.hostname.split(".")[0].lower()}
        return names

    @property
    def is_local(self) -> bool:
        return bool(self.local_names & local_hostnames())


class Project(BaseModel):
    key: str
    machine: str | None = None
    path: str = ""
    tmux: bool | None = None
    session: str | None = None
    tmux_path: str | None = None
    description: str | None = None

    @field_validator("path")
    @classmethod
    def validate_project_path(cls, value: str) -> str:
        return validate_path(value, field="project path")

    @field_validator("tmux_path")
    @classmethod
    def validate_project_tmux_path(cls, value: str | None) -> str | None:
        if value is None:
            return None
        return validate_path(value, field="project tmux_path")

    @property
    def workdir(self) -> str:
        """Where to actually land: `tmux_path` when set, otherwise `path`.

        `tmux_path` is an override for the uncommon case, not a second address
        every project carries -- 8 of 250 entries here have one (3%). It earns
        its place because when the two do differ, the difference matters: the
        project is ~/Projects/agents but the session runs in
        ~/Projects/agents/toggl-agent-git, and landing at the root would start
        a second session next to the one already there. The rest of the time
        the default is simply right and the field stays absent.
        """
        return self.tmux_path or self.path

    @property
    def session_name(self) -> str:
        # An explicit session is used verbatim; a key-derived one is slugified,
        # because tmux session names may not contain ":" or ".". Shares
        # session_slug with _cmux.py and ~/.bashrc.d/20-tmux.bash so a project registered
        # as "thumb.im" resolves to the same "thumb-im" session everywhere.
        return self.session or session_slug(self.key)

    def to_dict(self) -> dict:
        data = {"machine": self.machine, "path": self.path}
        if self.tmux is not None:
            data["tmux"] = self.tmux
        # tmux_path is optional throughout: written only when the session
        # really runs somewhere other than the project directory. A project
        # whose work happens at its own root carries no tmux_path at all.
        if self.tmux_path and self.tmux_path != self.path:
            data["tmux_path"] = self.tmux_path
        if self.session:
            data["tmux_session"] = self.session
        if self.description:
            data["description"] = self.description
        return {key: value for key, value in data.items() if value is not None}


class Plan(BaseModel):
    """How to reach a project: everything workon needs to act."""

    project: Project
    machine: Machine | None = None
    local: bool
    # Where to land -- the project's tmux_path when it has one, else its path.
    path: str
    # The project directory itself, kept for display so the registry entry is
    # still recognizable when the two differ.
    project_path: str
    session: str
    tmux: bool
    argv: list[str] = Field(default_factory=list)

    @property
    def nested(self) -> bool:
        return self.path != self.project_path


def remote_path_expr(path: str) -> str:
    """Shell expression for `path` as evaluated on the *remote* host.

    A leading "~" has to survive quoting and expand over there, not here: the
    remote home directory is the one that matters, and shlex.quote would turn
    "~/work" into a literal directory name.
    """
    if path == "~":
        return '"$HOME"'
    if path.startswith("~/"):
        return '"$HOME"/' + shlex.quote(path[2:])
    return shlex.quote(path)


class Registry(BaseModel):
    path: Path
    machines: dict[str, Machine] = Field(default_factory=dict)
    defaults: dict = Field(default_factory=dict)
    projects: dict[str, Project] = Field(default_factory=dict)

    @classmethod
    def load(cls, path: Path | None = None) -> "Registry":
        """Read the registry. A missing file is an empty registry, not an error.

        Callers that need content (resolving a project) raise their own error;
        `projects add` has to work before the file exists.
        """
        path = path or registry_path()
        if not path.is_file():
            return cls(path=path)

        data = tomllib.loads(path.read_text())
        machines = {
            key: Machine(
                key=key,
                host=value.get("host", key),
                hostname=value.get("hostname"),
            )
            for key, value in data.get("machines", {}).items()
        }
        projects = {
            key: Project(
                key=key,
                machine=value.get("machine"),
                path=value.get("path", ""),
                tmux=value.get("tmux"),
                # "session" is accepted as a spelling of "tmux_session" so an
                # entry copied out of a cmux session dump drops straight in.
                session=value.get("tmux_session", value.get("session")),
                tmux_path=value.get("tmux_path"),
                description=value.get("description"),
            )
            for key, value in data.get("projects", {}).items()
        }
        defaults = data.get("defaults", {})
        for field in ("home_dir", "work_dir"):
            if field in defaults:
                validate_path(defaults[field], field=f"defaults.{field}")
        unknown_machines = sorted(
            f"{project.key} -> {project.machine}"
            for project in projects.values()
            if project.machine is not None and project.machine not in machines
        )
        if unknown_machines:
            raise ValueError(
                "projects reference unknown machines: " + ", ".join(unknown_machines)
            )
        return cls(
            path=path,
            machines=machines,
            defaults=defaults,
            projects=projects,
        )

    def save(self) -> None:
        """Rewrite the file, preserving comments.

        tomlkit rather than tomli-w: the file carries the header explaining what
        each table is for, and a plain TOML writer would drop it on first edit.
        """
        import tomlkit

        from _cmux import write_atomic

        if self.path.is_file():
            doc = tomlkit.parse(self.path.read_text())
        else:
            doc = tomlkit.parse(NEW_FILE_HEADER)

        existing_machines = doc.get("machines")
        machines = tomlkit.table(is_super_table=True)
        for key in sorted(self.machines):
            machine = self.machines[key]
            old_entry = (
                existing_machines.get(key)
                if existing_machines is not None and hasattr(existing_machines, "get")
                else None
            )
            entry = old_entry if hasattr(old_entry, "get") else tomlkit.table()
            self._update_toml_table(entry, {"host": machine.host, "hostname": machine.hostname})
            machines[key] = entry
        doc["machines"] = machines

        if self.defaults:
            old_defaults = doc.get("defaults")
            defaults = old_defaults if hasattr(old_defaults, "get") else tomlkit.table()
            self._update_toml_table(
                defaults,
                {key: self.defaults[key] for key in sorted(self.defaults)},
            )
            doc["defaults"] = defaults

        existing_projects = doc.get("projects")
        projects = tomlkit.table(is_super_table=True)
        for key in sorted(self.projects):
            old_entry = (
                existing_projects.get(key)
                if existing_projects is not None and hasattr(existing_projects, "get")
                else None
            )
            entry = old_entry if hasattr(old_entry, "get") else tomlkit.table()
            self._update_toml_table(entry, self.projects[key].to_dict())
            projects[key] = entry
        doc["projects"] = projects

        self.path.parent.mkdir(parents=True, exist_ok=True)
        write_atomic(self.path, content=tomlkit.dumps(doc))

    @staticmethod
    def _update_toml_table(table, values: dict) -> None:
        """Update managed values while retaining comments on surviving keys."""
        values = {key: value for key, value in values.items() if value is not None}
        managed = set(table.keys())
        for key in managed - set(values):
            del table[key]
        for key, value in values.items():
            old = table.get(key)
            trivia = getattr(old, "trivia", None)
            table[key] = value
            new = table.get(key)
            if trivia is not None and hasattr(new, "trivia"):
                new.trivia.indent = trivia.indent
                new.trivia.comment_ws = trivia.comment_ws
                new.trivia.comment = trivia.comment
                new.trivia.trail = trivia.trail

    # -- lookup ----------------------------------------------------------

    def machine(self, name: str | None) -> Machine | None:
        """Resolve a machine by key, ssh name, or short ssh name."""
        if not name:
            return None
        if name in self.machines:
            return self.machines[name]
        wanted = name.lower()
        for machine in self.machines.values():
            if wanted in machine.lookup_names:
                return machine
        return None

    def project(self, name: str) -> Project | None:
        if name in self.projects:
            return self.projects[name]
        # Fall back to the slug, so `workon thumb-im` finds a project
        # registered as "thumb.im" -- that is the name tmux shows you.
        slug = session_slug(name)
        for project in self.projects.values():
            if session_slug(project.key) == slug or project.session_name == name:
                return project
        return None

    def projects_for_session_slug(
        self,
        slug: str,
        *,
        projects: dict[str, Project] | None = None,
    ) -> list[Project]:
        source = projects if projects is not None else self.projects
        return [
            project
            for project in source.values()
            if session_slug(project.session_name) == slug
        ]

    def local_machine(self) -> Machine | None:
        for machine in self.machines.values():
            if machine.is_local:
                return machine
        return None

    # -- defaults --------------------------------------------------------

    @property
    def home_dir(self) -> str:
        return self.defaults.get("home_dir", "~/Projects")

    @property
    def work_dir(self) -> str:
        return self.defaults.get("work_dir", "~/Work")

    @property
    def tmux_default(self) -> bool:
        """Whether a project with no `tmux` of its own gets a session.

        False: a project gets a tmux session because it says so, not because
        it failed to say otherwise. Opening a project is a cd and an activate
        until something asks for more -- `tmux = true` on the entry, `--tmux`
        on the command, or `tmux = true` under [defaults] to flip it globally.
        """
        return bool(self.defaults.get("tmux", False))

    # There is deliberately no machine_for_path(). A path under work_dir used
    # to imply work_machine, which read as a rule and behaved as a guess: the
    # roots are Syncthing-mirrored, so the same directory sits under the same
    # root on every Mac and implies nothing about where it is worked on. A
    # project names its machine or has none, and having none means "here".

    def default_dir(self, *, work: bool) -> str:
        return self.work_dir if work else self.home_dir

    # -- planning --------------------------------------------------------

    def plan(self, project: Project) -> Plan:
        """Work out how to reach `project` and build the command that does it."""
        machine = self.machine(project.machine)
        if project.machine is not None and machine is None:
            raise ValueError(
                f"project {project.key!r} references unknown machine {project.machine!r}"
            )
        local = machine is None or machine.is_local
        tmux = self.tmux_default if project.tmux is None else project.tmux
        session = project.session_name

        plan = Plan(
            project=project,
            machine=machine,
            local=local,
            path=project.workdir,
            project_path=project.path,
            session=session,
            tmux=tmux,
        )
        if not local:
            plan.argv = self._remote_argv(
                machine, path=project.workdir, session=session, tmux=tmux
            )
        return plan

    def _remote_argv(
        self, machine: Machine, *, path: str, session: str, tmux: bool
    ) -> list[str]:
        path_expr = remote_path_expr(path) if path else '"$HOME"'
        # Shared with cmux via _cmux.py, so the session workon opens and the
        # one cmux restores are the same session, built the same way.
        command = tmux_attach_command(session, path_expr, tmux=tmux)

        # bash -lc on both paths: the login profile is what puts Homebrew's
        # tmux on PATH, and mosh-server execs the command directly rather than
        # through a login shell.
        if shutil.which("mosh"):
            # "--" stops mosh parsing the command's own flags as its options.
            return ["mosh", machine.host, "--", "bash", "-lc", command]
        # ssh re-parses on the remote, so the command is quoted as one word.
        # Falling back rather than failing: ssh reaches the same session, it
        # just does not survive the laptop sleeping.
        return ["ssh", "-t", machine.host, f"bash -lc {shlex.quote(command)}"]
