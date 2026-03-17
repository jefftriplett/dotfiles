#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pydantic>=2.0",
#     "typer>=0.9",
#     "tomli-w>=1.0",
# ]
# ///
"""
Brewfile to TOML manager.

Reads all Brewfile* files and generates a unified brew.toml that tracks
which machines have which packages installed. Supports marking packages
for install/uninstall across machines.
"""

from __future__ import annotations

import re
import socket
import subprocess
import tomllib
from datetime import datetime
from pathlib import Path
from typing import Annotated, Any

import tomli_w
import typer
from pydantic import BaseModel, Field

# Default paths
DEFAULT_BREWFILE_DIR = Path.home() / ".homesick/repos/dotfiles/home"
DEFAULT_OUTPUT = Path.home() / "brew.toml"


# Pydantic Models
class PackageOptions(BaseModel):
    """Options that can be applied to brew packages."""

    link: bool | None = None
    args: list[str] = Field(default_factory=list)
    restart_service: str | bool | None = None


class Package(BaseModel):
    """A package entry with machine tracking."""

    machines: list[str] = Field(default_factory=list)
    install: list[str] = Field(default_factory=list)
    uninstall: list[str] = Field(default_factory=list)
    options: PackageOptions | None = None


class MasPackage(Package):
    """Mac App Store package with app ID."""

    id: int


class BrewToml(BaseModel):
    """The complete brew.toml structure."""

    meta: dict[str, Any] = Field(default_factory=dict)
    taps: dict[str, Package] = Field(default_factory=dict)
    brews: dict[str, Package] = Field(default_factory=dict)
    casks: dict[str, Package] = Field(default_factory=dict)
    mas: dict[str, MasPackage] = Field(default_factory=dict)
    whalebrew: dict[str, Package] = Field(default_factory=dict)
    go: dict[str, Package] = Field(default_factory=dict)
    cargo: dict[str, Package] = Field(default_factory=dict)
    uv: dict[str, Package] = Field(default_factory=dict)


# Regex patterns for parsing Brewfiles
PATTERNS = {
    "tap": re.compile(r'^tap\s+"([^"]+)"'),
    "brew": re.compile(r'^brew\s+"([^"]+)"(?:,\s*(.+))?$'),
    "cask": re.compile(r'^cask\s+"([^"]+)"'),
    "mas": re.compile(r'^mas\s+"([^"]+)",\s*id:\s*(\d+)'),
    "whalebrew": re.compile(r'^whalebrew\s+"([^"]+)"'),
    "go": re.compile(r'^go\s+"([^"]+)"'),
    "cargo": re.compile(r'^cargo\s+"([^"]+)"'),
    "uv": re.compile(r'^uv\s+"([^"]+)"'),
}

# Options patterns
LINK_PATTERN = re.compile(r"link:\s*(true|false)")
ARGS_PATTERN = re.compile(r'args:\s*\[([^\]]+)\]')
RESTART_PATTERN = re.compile(r"restart_service:\s*(:?\w+)")


def parse_brew_options(options_str: str | None) -> PackageOptions | None:
    """Parse brew package options from the options string."""
    if not options_str:
        return None

    options = PackageOptions()
    has_options = False

    # Parse link option
    if match := LINK_PATTERN.search(options_str):
        options.link = match.group(1) == "true"
        has_options = True

    # Parse args option
    if match := ARGS_PATTERN.search(options_str):
        args_str = match.group(1)
        # Parse quoted strings from args
        options.args = [s.strip().strip('"').strip("'") for s in args_str.split(",")]
        has_options = True

    # Parse restart_service option
    if match := RESTART_PATTERN.search(options_str):
        value = match.group(1)
        if value == "true":
            options.restart_service = True
        elif value == ":changed":
            options.restart_service = "changed"
        else:
            options.restart_service = value
        has_options = True

    return options if has_options else None


def get_machine_name(filepath: Path) -> str:
    """Extract machine name from Brewfile path."""
    name = filepath.name
    if name == "Brewfile":
        return "Brewfile"
    elif name.startswith("Brewfile."):
        return name[9:]  # Remove "Brewfile." prefix
    return name


def parse_brewfile(filepath: Path) -> dict[str, list[tuple[str, Any]]]:
    """Parse a Brewfile and return entries by type."""
    entries: dict[str, list[tuple[str, Any]]] = {
        "tap": [],
        "brew": [],
        "cask": [],
        "mas": [],
        "whalebrew": [],
        "go": [],
        "cargo": [],
        "uv": [],
    }

    content = filepath.read_text()
    for line in content.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        for entry_type, pattern in PATTERNS.items():
            if match := pattern.match(line):
                if entry_type == "brew":
                    name = match.group(1)
                    options = parse_brew_options(match.group(2))
                    entries["brew"].append((name, options))
                elif entry_type == "mas":
                    name = match.group(1)
                    app_id = int(match.group(2))
                    entries["mas"].append((name, app_id))
                else:
                    entries[entry_type].append((match.group(1), None))
                break

    return entries


def find_brewfiles(directory: Path) -> list[Path]:
    """Find all Brewfile* files, excluding .bak files."""
    files = []
    for f in directory.glob("Brewfile*"):
        if f.suffix == ".bak":
            continue
        if f.suffix == ".cog":
            continue  # Skip cog template files
        if f.is_file():
            files.append(f)
    return sorted(files)


def load_existing_toml(filepath: Path) -> BrewToml | None:
    """Load existing brew.toml to preserve install/uninstall lists."""
    if not filepath.exists():
        return None
    try:
        with open(filepath, "rb") as f:
            data = tomllib.load(f)
        return BrewToml.model_validate(data)
    except Exception:
        return None


def merge_package(
    existing: Package | None,
    machines: list[str],
    options: PackageOptions | None = None,
) -> Package:
    """Merge new machine data with existing package, preserving install/uninstall."""
    if existing:
        return Package(
            machines=sorted(set(machines)),
            install=existing.install,
            uninstall=existing.uninstall,
            options=options or existing.options,
        )
    return Package(
        machines=sorted(set(machines)),
        install=[],
        uninstall=[],
        options=options,
    )


def merge_mas_package(
    existing: MasPackage | None,
    machines: list[str],
    app_id: int,
) -> MasPackage:
    """Merge new machine data with existing MAS package."""
    if existing:
        return MasPackage(
            id=app_id,
            machines=sorted(set(machines)),
            install=existing.install,
            uninstall=existing.uninstall,
        )
    return MasPackage(
        id=app_id,
        machines=sorted(set(machines)),
        install=[],
        uninstall=[],
    )


def generate_toml(directory: Path, output: Path) -> BrewToml:
    """Generate brew.toml from all Brewfiles."""
    brewfiles = find_brewfiles(directory)
    existing = load_existing_toml(output)

    # Collect all entries across machines
    all_entries: dict[str, dict[str, dict[str, Any]]] = {
        "taps": {},
        "brews": {},
        "casks": {},
        "mas": {},
        "whalebrew": {},
        "go": {},
        "cargo": {},
        "uv": {},
    }

    machines = []
    for brewfile in brewfiles:
        machine = get_machine_name(brewfile)
        machines.append(machine)
        entries = parse_brewfile(brewfile)

        for name, _ in entries["tap"]:
            if name not in all_entries["taps"]:
                all_entries["taps"][name] = {"machines": []}
            all_entries["taps"][name]["machines"].append(machine)

        for name, options in entries["brew"]:
            if name not in all_entries["brews"]:
                all_entries["brews"][name] = {"machines": [], "options": None}
            all_entries["brews"][name]["machines"].append(machine)
            if options:
                all_entries["brews"][name]["options"] = options

        for name, _ in entries["cask"]:
            if name not in all_entries["casks"]:
                all_entries["casks"][name] = {"machines": []}
            all_entries["casks"][name]["machines"].append(machine)

        for name, app_id in entries["mas"]:
            if name not in all_entries["mas"]:
                all_entries["mas"][name] = {"machines": [], "id": app_id}
            all_entries["mas"][name]["machines"].append(machine)

        for name, _ in entries["whalebrew"]:
            if name not in all_entries["whalebrew"]:
                all_entries["whalebrew"][name] = {"machines": []}
            all_entries["whalebrew"][name]["machines"].append(machine)

        for name, _ in entries["go"]:
            if name not in all_entries["go"]:
                all_entries["go"][name] = {"machines": []}
            all_entries["go"][name]["machines"].append(machine)

        for name, _ in entries["cargo"]:
            if name not in all_entries["cargo"]:
                all_entries["cargo"][name] = {"machines": []}
            all_entries["cargo"][name]["machines"].append(machine)

        for name, _ in entries["uv"]:
            if name not in all_entries["uv"]:
                all_entries["uv"][name] = {"machines": []}
            all_entries["uv"][name]["machines"].append(machine)

    # Build the BrewToml structure
    result = BrewToml(
        meta={
            "machines": sorted(machines),
            "generated": datetime.now().isoformat(),
        }
    )

    # Merge with existing data to preserve install/uninstall lists
    for name, data in sorted(all_entries["taps"].items()):
        existing_pkg = existing.taps.get(name) if existing else None
        result.taps[name] = merge_package(existing_pkg, data["machines"])

    for name, data in sorted(all_entries["brews"].items()):
        existing_pkg = existing.brews.get(name) if existing else None
        result.brews[name] = merge_package(
            existing_pkg, data["machines"], data.get("options")
        )

    for name, data in sorted(all_entries["casks"].items()):
        existing_pkg = existing.casks.get(name) if existing else None
        result.casks[name] = merge_package(existing_pkg, data["machines"])

    for name, data in sorted(all_entries["mas"].items()):
        existing_pkg = existing.mas.get(name) if existing else None
        result.mas[name] = merge_mas_package(existing_pkg, data["machines"], data["id"])

    for name, data in sorted(all_entries["whalebrew"].items()):
        existing_pkg = existing.whalebrew.get(name) if existing else None
        result.whalebrew[name] = merge_package(existing_pkg, data["machines"])

    for name, data in sorted(all_entries["go"].items()):
        existing_pkg = existing.go.get(name) if existing else None
        result.go[name] = merge_package(existing_pkg, data["machines"])

    for name, data in sorted(all_entries["cargo"].items()):
        existing_pkg = existing.cargo.get(name) if existing else None
        result.cargo[name] = merge_package(existing_pkg, data["machines"])

    for name, data in sorted(all_entries["uv"].items()):
        existing_pkg = existing.uv.get(name) if existing else None
        result.uv[name] = merge_package(existing_pkg, data["machines"])

    return result


def package_to_dict(pkg: Package) -> dict[str, Any]:
    """Convert a Package to a dict for TOML serialization."""
    result: dict[str, Any] = {"machines": pkg.machines}

    if pkg.options:
        opts = {}
        if pkg.options.link is not None:
            opts["link"] = pkg.options.link
        if pkg.options.args:
            opts["args"] = pkg.options.args
        if pkg.options.restart_service is not None:
            opts["restart_service"] = pkg.options.restart_service
        if opts:
            result["options"] = opts

    if pkg.install:
        result["install"] = pkg.install
    if pkg.uninstall:
        result["uninstall"] = pkg.uninstall

    return result


def mas_package_to_dict(pkg: MasPackage) -> dict[str, Any]:
    """Convert a MasPackage to a dict for TOML serialization."""
    result: dict[str, Any] = {
        "id": pkg.id,
        "machines": pkg.machines,
    }
    if pkg.install:
        result["install"] = pkg.install
    if pkg.uninstall:
        result["uninstall"] = pkg.uninstall
    return result


def write_toml(data: BrewToml, output: Path) -> None:
    """Write BrewToml to file."""
    result: dict[str, Any] = {"meta": data.meta}

    if data.taps:
        result["taps"] = {k: package_to_dict(v) for k, v in data.taps.items()}
    if data.brews:
        result["brews"] = {k: package_to_dict(v) for k, v in data.brews.items()}
    if data.casks:
        result["casks"] = {k: package_to_dict(v) for k, v in data.casks.items()}
    if data.mas:
        result["mas"] = {k: mas_package_to_dict(v) for k, v in data.mas.items()}
    if data.whalebrew:
        result["whalebrew"] = {k: package_to_dict(v) for k, v in data.whalebrew.items()}
    if data.go:
        result["go"] = {k: package_to_dict(v) for k, v in data.go.items()}
    if data.cargo:
        result["cargo"] = {k: package_to_dict(v) for k, v in data.cargo.items()}
    if data.uv:
        result["uv"] = {k: package_to_dict(v) for k, v in data.uv.items()}

    with open(output, "wb") as f:
        tomli_w.dump(result, f)


def format_brew_entry(name: str, pkg: Package) -> str:
    """Format a brew entry for Brewfile."""
    if pkg.options:
        opts = []
        if pkg.options.link is not None:
            opts.append(f"link: {'true' if pkg.options.link else 'false'}")
        if pkg.options.args:
            args_str = ", ".join(f'"{a}"' for a in pkg.options.args)
            opts.append(f"args: [{args_str}]")
        if pkg.options.restart_service is not None:
            if pkg.options.restart_service is True:
                opts.append("restart_service: true")
            elif pkg.options.restart_service == "changed":
                opts.append("restart_service: :changed")
            else:
                opts.append(f"restart_service: {pkg.options.restart_service}")
        if opts:
            return f'brew "{name}", {", ".join(opts)}'
    return f'brew "{name}"'


def get_changes(data: BrewToml) -> dict[str, dict[str, list[tuple[str, str, Any]]]]:
    """Get all pending install/uninstall changes grouped by machine."""
    changes: dict[str, dict[str, list[tuple[str, str, Any]]]] = {}

    def add_change(machine: str, action: str, pkg_type: str, name: str, extra: Any = None):
        if machine not in changes:
            changes[machine] = {"install": [], "uninstall": []}
        changes[machine][action].append((pkg_type, name, extra))

    for name, pkg in data.taps.items():
        for machine in pkg.install:
            add_change(machine, "install", "tap", name)
        for machine in pkg.uninstall:
            add_change(machine, "uninstall", "tap", name)

    for name, pkg in data.brews.items():
        for machine in pkg.install:
            add_change(machine, "install", "brew", name, pkg.options)
        for machine in pkg.uninstall:
            add_change(machine, "uninstall", "brew", name)

    for name, pkg in data.casks.items():
        for machine in pkg.install:
            add_change(machine, "install", "cask", name)
        for machine in pkg.uninstall:
            add_change(machine, "uninstall", "cask", name)

    for name, pkg in data.mas.items():
        for machine in pkg.install:
            add_change(machine, "install", "mas", name, pkg.id)
        for machine in pkg.uninstall:
            add_change(machine, "uninstall", "mas", name, pkg.id)

    for name, pkg in data.whalebrew.items():
        for machine in pkg.install:
            add_change(machine, "install", "whalebrew", name)
        for machine in pkg.uninstall:
            add_change(machine, "uninstall", "whalebrew", name)

    for name, pkg in data.go.items():
        for machine in pkg.install:
            add_change(machine, "install", "go", name)
        for machine in pkg.uninstall:
            add_change(machine, "uninstall", "go", name)

    for name, pkg in data.cargo.items():
        for machine in pkg.install:
            add_change(machine, "install", "cargo", name)
        for machine in pkg.uninstall:
            add_change(machine, "uninstall", "cargo", name)

    for name, pkg in data.uv.items():
        for machine in pkg.install:
            add_change(machine, "install", "uv", name)
        for machine in pkg.uninstall:
            add_change(machine, "uninstall", "uv", name)

    return changes


def get_brewfile_path(directory: Path, machine: str) -> Path:
    """Get the Brewfile path for a machine."""
    if machine == "Brewfile":
        return directory / "Brewfile"
    return directory / f"Brewfile.{machine}"


def apply_changes(directory: Path, data: BrewToml) -> None:
    """Apply install/uninstall changes to Brewfiles."""
    changes = get_changes(data)

    for machine, machine_changes in changes.items():
        brewfile = get_brewfile_path(directory, machine)
        if not brewfile.exists():
            typer.echo(f"Warning: {brewfile} does not exist, skipping")
            continue

        content = brewfile.read_text()
        lines = content.splitlines()

        # Process uninstalls - remove matching lines
        for pkg_type, name, _ in machine_changes["uninstall"]:
            pattern = PATTERNS[pkg_type]
            new_lines = []
            for line in lines:
                stripped = line.strip()
                if match := pattern.match(stripped):
                    if match.group(1) == name:
                        continue  # Skip this line (remove it)
                new_lines.append(line)
            lines = new_lines

        # Process installs - add new lines at appropriate section
        for pkg_type, name, extra in machine_changes["install"]:
            # Check if already exists
            pattern = PATTERNS[pkg_type]
            exists = False
            for line in lines:
                stripped = line.strip()
                if match := pattern.match(stripped):
                    if match.group(1) == name:
                        exists = True
                        break
            if exists:
                continue

            # Format the new entry
            if pkg_type == "tap":
                entry = f'tap "{name}"'
            elif pkg_type == "brew":
                pkg = Package(machines=[], options=extra)
                entry = format_brew_entry(name, pkg)
            elif pkg_type == "cask":
                entry = f'cask "{name}"'
            elif pkg_type == "mas":
                entry = f'mas "{name}", id: {extra}'
            elif pkg_type == "whalebrew":
                entry = f'whalebrew "{name}"'
            elif pkg_type == "go":
                entry = f'go "{name}"'
            elif pkg_type == "cargo":
                entry = f'cargo "{name}"'
            elif pkg_type == "uv":
                entry = f'uv "{name}"'
            else:
                continue

            # Find the right place to insert (after last entry of same type)
            insert_idx = len(lines)
            for i, line in enumerate(lines):
                stripped = line.strip()
                if stripped.startswith(f'{pkg_type} "'):
                    insert_idx = i + 1

            lines.insert(insert_idx, entry)

        # Write back
        brewfile.write_text("\n".join(lines) + "\n")
        typer.echo(f"Updated {brewfile}")

    # Clear install/uninstall lists after applying
    for pkg in data.taps.values():
        pkg.install.clear()
        pkg.uninstall.clear()
    for pkg in data.brews.values():
        pkg.install.clear()
        pkg.uninstall.clear()
    for pkg in data.casks.values():
        pkg.install.clear()
        pkg.uninstall.clear()
    for pkg in data.mas.values():
        pkg.install.clear()
        pkg.uninstall.clear()
    for pkg in data.whalebrew.values():
        pkg.install.clear()
        pkg.uninstall.clear()
    for pkg in data.go.values():
        pkg.install.clear()
        pkg.uninstall.clear()
    for pkg in data.cargo.values():
        pkg.install.clear()
        pkg.uninstall.clear()
    for pkg in data.uv.values():
        pkg.install.clear()
        pkg.uninstall.clear()


def get_current_machine() -> str:
    """Get the current machine name from hostname."""
    hostname = socket.gethostname()
    # Remove .local suffix if present
    if hostname.endswith(".local"):
        hostname = hostname[:-6]
    return hostname


def get_installed_packages() -> dict[str, list[tuple[str, Any]]]:
    """Get currently installed packages using brew bundle dump."""
    result = subprocess.run(
        ["brew", "bundle", "dump", "--file=-", "--no-vscode"],
        capture_output=True,
        text=True,
        check=True,
    )

    entries: dict[str, list[tuple[str, Any]]] = {
        "tap": [],
        "brew": [],
        "cask": [],
        "mas": [],
        "whalebrew": [],
        "go": [],
        "cargo": [],
        "uv": [],
    }

    for line in result.stdout.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue

        for entry_type, pattern in PATTERNS.items():
            if match := pattern.match(line):
                if entry_type == "brew":
                    name = match.group(1)
                    options = parse_brew_options(match.group(2))
                    entries["brew"].append((name, options))
                elif entry_type == "mas":
                    name = match.group(1)
                    app_id = int(match.group(2))
                    entries["mas"].append((name, app_id))
                else:
                    entries[entry_type].append((match.group(1), None))
                break

    return entries


def compare_packages(
    brewfile_entries: dict[str, list[tuple[str, Any]]],
    installed_entries: dict[str, list[tuple[str, Any]]],
) -> tuple[dict[str, set[str]], dict[str, set[str]]]:
    """Compare Brewfile entries with installed packages.

    Returns (missing_from_system, missing_from_brewfile)
    """
    missing_from_system: dict[str, set[str]] = {}
    missing_from_brewfile: dict[str, set[str]] = {}

    for pkg_type in ["tap", "brew", "cask", "mas", "whalebrew", "go", "cargo", "uv"]:
        brewfile_names = {entry[0] for entry in brewfile_entries.get(pkg_type, [])}
        installed_names = {entry[0] for entry in installed_entries.get(pkg_type, [])}

        # In Brewfile but not installed
        missing = brewfile_names - installed_names
        if missing:
            missing_from_system[pkg_type] = missing

        # Installed but not in Brewfile
        extra = installed_names - brewfile_names
        if extra:
            missing_from_brewfile[pkg_type] = extra

    return missing_from_system, missing_from_brewfile


# CLI
app = typer.Typer(help="Brewfile to TOML manager")


@app.command()
def generate(
    directory: Annotated[
        Path, typer.Option("--dir", "-d", help="Directory containing Brewfiles")
    ] = DEFAULT_BREWFILE_DIR,
    output: Annotated[
        Path, typer.Option("--output", "-o", help="Output TOML file path")
    ] = DEFAULT_OUTPUT,
) -> None:
    """Generate brew.toml from all Brewfiles."""
    typer.echo(f"Scanning {directory} for Brewfiles...")
    data = generate_toml(directory, output)
    write_toml(data, output)
    typer.echo(f"Generated {output}")
    typer.echo(f"  Machines: {len(data.meta.get('machines', []))}")
    typer.echo(f"  Taps: {len(data.taps)}")
    typer.echo(f"  Brews: {len(data.brews)}")
    typer.echo(f"  Casks: {len(data.casks)}")
    typer.echo(f"  MAS apps: {len(data.mas)}")


@app.command()
def pending(
    toml_file: Annotated[
        Path, typer.Option("--file", "-f", help="brew.toml file path")
    ] = DEFAULT_OUTPUT,
) -> None:
    """Show pending install/uninstall changes from brew.toml."""
    if not toml_file.exists():
        typer.echo(f"Error: {toml_file} does not exist. Run 'generate' first.")
        raise typer.Exit(1)

    with open(toml_file, "rb") as f:
        raw = tomllib.load(f)
    data = BrewToml.model_validate(raw)
    changes = get_changes(data)

    if not changes:
        typer.echo("No pending changes.")
        return

    for machine, machine_changes in sorted(changes.items()):
        typer.echo(f"\n{machine}:")
        for pkg_type, name, _ in machine_changes["install"]:
            typer.echo(f"  + {pkg_type} \"{name}\"")
        for pkg_type, name, _ in machine_changes["uninstall"]:
            typer.echo(f"  - {pkg_type} \"{name}\"")


@app.command()
def sync(
    directory: Annotated[
        Path, typer.Option("--dir", "-d", help="Directory containing Brewfiles")
    ] = DEFAULT_BREWFILE_DIR,
    toml_file: Annotated[
        Path, typer.Option("--file", "-f", help="brew.toml file path")
    ] = DEFAULT_OUTPUT,
) -> None:
    """Apply install/uninstall changes to Brewfiles."""
    if not toml_file.exists():
        typer.echo(f"Error: {toml_file} does not exist. Run 'generate' first.")
        raise typer.Exit(1)

    with open(toml_file, "rb") as f:
        raw = tomllib.load(f)
    data = BrewToml.model_validate(raw)
    changes = get_changes(data)

    if not changes:
        typer.echo("No pending changes.")
        return

    apply_changes(directory, data)
    write_toml(data, toml_file)
    typer.echo("Changes applied. Install/uninstall lists cleared.")


@app.command()
def dump(
    directory: Annotated[
        Path, typer.Option("--dir", "-d", help="Directory containing Brewfiles")
    ] = DEFAULT_BREWFILE_DIR,
) -> None:
    """Dump current system packages to this machine's Brewfile."""
    machine = get_current_machine()
    brewfile = get_brewfile_path(directory, machine)

    typer.echo(f"Machine: {machine}")
    typer.echo(f"Dumping to: {brewfile}")

    result = subprocess.run(
        ["brew", "bundle", "dump", f"--file={brewfile}", "--force", "--no-vscode"],
        capture_output=True,
        text=True,
    )

    if result.returncode != 0:
        typer.echo(f"Error: {result.stderr}")
        raise typer.Exit(1)

    typer.echo("Done!")


@app.command()
def diff(
    directory: Annotated[
        Path, typer.Option("--dir", "-d", help="Directory containing Brewfiles")
    ] = DEFAULT_BREWFILE_DIR,
) -> None:
    """Compare installed packages with this machine's Brewfile."""
    machine = get_current_machine()
    brewfile = get_brewfile_path(directory, machine)

    typer.echo(f"Machine: {machine}")
    typer.echo(f"Comparing with: {brewfile}")

    if not brewfile.exists():
        typer.echo(f"Error: {brewfile} does not exist.")
        typer.echo(f"Run 'dump' to create it, or create Brewfile.{machine}")
        raise typer.Exit(1)

    typer.echo("Getting installed packages...")
    installed = get_installed_packages()

    typer.echo("Parsing Brewfile...")
    brewfile_entries = parse_brewfile(brewfile)

    missing_from_system, missing_from_brewfile = compare_packages(
        brewfile_entries, installed
    )

    if not missing_from_system and not missing_from_brewfile:
        typer.echo("\nNo differences found.")
        return

    if missing_from_system:
        typer.echo("\n[red]In Brewfile but NOT installed:[/red]")
        for pkg_type, names in sorted(missing_from_system.items()):
            for name in sorted(names):
                typer.echo(f"  - {pkg_type} \"{name}\"")

    if missing_from_brewfile:
        typer.echo("\n[green]Installed but NOT in Brewfile:[/green]")
        for pkg_type, names in sorted(missing_from_brewfile.items()):
            for name in sorted(names):
                typer.echo(f"  + {pkg_type} \"{name}\"")

    typer.echo("\nTo sync:")
    typer.echo("  brew bundle install  # Install missing packages")
    typer.echo("  brew bundle cleanup  # Remove extra packages")
    typer.echo(f"  uv run {__file__} dump  # Update Brewfile with installed")


if __name__ == "__main__":
    app()
