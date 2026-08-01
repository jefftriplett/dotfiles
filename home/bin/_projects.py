"""Shared model for the project registry in ~/Projects/projects.toml.

Used by the `projects` CLI and, through it, by the `workon` and `mkproject`
shell functions in ~/.workon.bash.

The registry answers one question: given a project name, which machine is it
on, where does it live there, and what tmux session holds it. That was
previously spread across a project's .envrc (`use tmux NAME --machine X`), the
cmux session dump, and the directory scan in ~/.workon.bash, so the same fact
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
from pathlib import Path

from pydantic import BaseModel, ConfigDict, Field

from _cmux import local_hostnames, session_slug

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
# [defaults]        `tmux` toggles attaching a tmux session; `home_machine` and
#                   `work_machine` decide where auto-registered projects land,
#                   based on whether the path is under `home_dir` or `work_dir`.
#
# [projects.<key>]  `machine` names a [machines] key, `path` is the project
#                   directory on that machine. All optional: `tmux_path` is the
#                   checkout inside it the session actually runs in,
#                   `tmux_session` the session name (defaults to the key), and
#                   `tmux` overrides the [defaults] setting.
"""


def registry_path() -> Path:
    override = os.environ.get("PROJECTS_TOML", "").strip()
    return Path(override).expanduser() if override else DEFAULT_REGISTRY


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

    @property
    def workdir(self) -> str:
        """Where to actually land.

        `path` identifies the project; `tmux_path` is the checkout inside it
        the work happens in. They are separate fields because the two differ
        constantly -- the project is ~/Projects/django-news.com but the session
        runs in ~/Projects/django-news.com/django-news.com-git -- and
        collapsing them would lose whichever one you did not keep.
        """
        return self.tmux_path or self.path

    @property
    def session_name(self) -> str:
        # An explicit session is used verbatim; a key-derived one is slugified,
        # because tmux session names may not contain ":" or ".". Shares
        # session_slug with _cmux.py and ~/.bash_tmux so a project registered
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
        return cls(
            path=path,
            machines=machines,
            defaults=data.get("defaults", {}),
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

        machines = tomlkit.table(is_super_table=True)
        for key in sorted(self.machines):
            machine = self.machines[key]
            entry = tomlkit.table()
            entry["host"] = machine.host
            if machine.hostname:
                entry["hostname"] = machine.hostname
            machines[key] = entry
        doc["machines"] = machines

        if self.defaults:
            defaults = tomlkit.table()
            for key in sorted(self.defaults):
                defaults[key] = self.defaults[key]
            doc["defaults"] = defaults

        projects = tomlkit.table(is_super_table=True)
        for key in sorted(self.projects):
            entry = tomlkit.table()
            for field_name, value in self.projects[key].to_dict().items():
                entry[field_name] = value
            projects[key] = entry
        doc["projects"] = projects

        self.path.parent.mkdir(parents=True, exist_ok=True)
        write_atomic(self.path, content=tomlkit.dumps(doc))

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
        return bool(self.defaults.get("tmux", True))

    def machine_for_path(self, path: str) -> str | None:
        """Which machine a path implies, per the home_dir/work_dir split.

        This is what makes `mkproject foo --work` enough: the directory
        it lands in decides the machine, so the common case needs no --machine.
        """
        normalized = str(Path(path).expanduser())
        for base, key in (
            (self.work_dir, self.defaults.get("work_machine")),
            (self.home_dir, self.defaults.get("home_machine")),
        ):
            if not key:
                continue
            root = str(Path(base).expanduser())
            if normalized == root or normalized.startswith(root + os.sep):
                return key
        return None

    def default_dir(self, *, work: bool) -> str:
        return self.work_dir if work else self.home_dir

    # -- planning --------------------------------------------------------

    def plan(self, project: Project) -> Plan:
        """Work out how to reach `project` and build the command that does it."""
        machine = self.machine(project.machine)
        # An unknown or unset machine means "here". Better than refusing: a
        # registry entry that predates a machine rename should still open.
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
        if tmux:
            attach = f"tmux new-session -A -s {shlex.quote(session)} -c {path_expr}"
            # cd first so a freshly created session lands in the right place
            # even if tmux's -c is bypassed; ";" not "&&" so attaching to an
            # existing session still works when the directory is missing.
            command = f"cd {path_expr}; {attach}"
        else:
            command = f"cd {path_expr}; exec bash -l"

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
