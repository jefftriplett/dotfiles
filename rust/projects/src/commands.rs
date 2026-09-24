//! The `projects` subcommands, other than import (import.rs) and the
//! workon/mkproject shell emitters (shell.rs).

use std::collections::BTreeMap;
use std::env;
use std::io::{BufRead, Write};
use std::process::Command;
use std::thread;

use indexmap::IndexMap;
use toml_edit::{DocumentMut, Item, Value};

use crate::registry::{Machine, Project, Registry, RegistryLock, registry_path};
use crate::tmux::{self, ProbeError, TmuxSession};
use crate::util::{
    Style, cmux_config_dir, expand_str, fail, join, local_hostnames, paint, paint_if, py_repr,
    quote, remote_path_expr, run_captured, session_slug, stderr_colour, tildify, validate_path,
    warn,
};

/// Err carries the exit code; the message has already been printed.
pub type Result<T = ()> = std::result::Result<T, i32>;

pub fn out(message: &str) {
    println!("{message}");
}

pub fn load() -> Result<Registry> {
    let loaded = registry_path().and_then(Registry::load);
    loaded.map_err(|err| {
        fail(&format!("Could not load project registry: {err}"));
        2
    })
}

/// Hold one interprocess lock across a mutating command.
pub fn locked(command: impl FnOnce() -> Result) -> Result {
    let path = registry_path().map_err(|err| {
        fail(&err);
        2
    })?;
    let _lock = RegistryLock::acquire(&path).map_err(|err| {
        fail(&format!("Could not lock {}: {err}", path.display()));
        2
    })?;
    command()
}

fn save(registry: &Registry) -> Result {
    registry.save().map_err(|err| {
        fail(&format!(
            "Could not write {}: {err}",
            registry.path.display()
        ));
        1
    })
}

pub fn mutation_path(value: &str, field: &str) -> Result<String> {
    validate_path(&tildify(value), field).map_err(|err| {
        fail(&err);
        2
    })
}

fn unknown_machine(name: &str) -> i32 {
    fail(&format!("Unknown machine: {name}"));
    fail(&format!(
        "Add it with: projects machines add {}",
        quote(name)
    ));
    1
}

pub fn ensure_session_slug_available(
    registry: &Registry,
    project: &Project,
    projects: Option<&IndexMap<String, Project>>,
) -> Result {
    let slug = session_slug(&project.session_name());
    let mut conflicts: Vec<&str> = registry
        .projects_for_session_slug(&slug, projects)
        .into_iter()
        .filter(|found| found.key != project.key)
        .map(|found| found.key.as_str())
        .collect();
    if conflicts.is_empty() {
        return Ok(());
    }
    conflicts.sort();
    fail(&format!(
        "tmux session slug {} for {} collides with: {}",
        py_repr(&slug),
        py_repr(&project.key),
        conflicts.join(", ")
    ));
    fail("Choose a different project name or pass a unique --session.");
    Err(1)
}

pub fn require_project<'a>(
    registry: &'a Registry,
    name: &str,
    not_found_code: i32,
) -> Result<&'a Project> {
    registry.project(name).ok_or_else(|| {
        fail(&format!(
            "No project named {} in {}",
            py_repr(name),
            registry.path.display()
        ));
        eprintln!(
            "Register it with: {}",
            paint_if(
                stderr_colour(),
                Style::Name,
                &format!("projects add {}", quote(name))
            )
        );
        not_found_code
    })
}

fn same_machine(a: Option<&Machine>, b: Option<&Machine>) -> bool {
    a.map(|m| &m.key) == b.map(|m| &m.key)
}

// -- list ----------------------------------------------------------------

/// Bare names by default, so the output pipes into grep, fzf, and xargs;
/// `--long` brings back machines, paths, and sessions.
pub fn list(machine: Option<&str>, long: bool, names_only: bool) -> Result {
    let registry = load()?;
    if registry.projects.is_empty() {
        // Guidance goes to stderr, so `list | wc -l` on an empty registry
        // counts zero.
        warn(&format!(
            "No projects registered in {}",
            registry.path.display()
        ));
        eprintln!(
            "Add one with projects add NAME, or import your existing \
             directories with projects import --dry-run."
        );
        return Ok(());
    }
    let long = long && !names_only;

    let wanted = match machine {
        Some(name) => Some(registry.machine(Some(name)).ok_or_else(|| {
            fail(&format!("Unknown machine: {name}"));
            1
        })?),
        None => None,
    };

    let mut keys: Vec<&String> = registry.projects.keys().collect();
    keys.sort();

    if !long {
        for key in keys {
            let project = &registry.projects[key];
            if wanted.is_some()
                && !same_machine(registry.machine(project.machine.as_deref()), wanted)
            {
                continue;
            }
            out(key);
        }
        return Ok(());
    }

    let mut grouped: BTreeMap<String, Vec<&Project>> = BTreeMap::new();
    for key in keys {
        let project = &registry.projects[key];
        if wanted.is_some() && !same_machine(registry.machine(project.machine.as_deref()), wanted) {
            continue;
        }
        grouped
            .entry(project.machine.clone().unwrap_or("(unset)".into()))
            .or_default()
            .push(project);
    }

    for (machine_key, projects) in grouped {
        let local = registry
            .machine(Some(&machine_key))
            .is_some_and(Machine::is_local);
        let mark = if local {
            format!(" {}", paint(Style::Muted, "(this machine)"))
        } else {
            String::new()
        };
        out(&format!(
            "{}{mark} {}",
            paint(Style::Machine, &machine_key),
            paint(Style::Muted, &format!("({})", projects.len()))
        ));
        for project in projects {
            let session = project.session_name();
            let suffix = if session != project.key {
                format!(" {}", paint(Style::Extra, &format!("[{session}]")))
            } else {
                String::new()
            };
            let nested = match &project.tmux_path {
                Some(tmux_path) => format!(
                    " {} {}",
                    paint(Style::Muted, "->"),
                    paint(Style::Path, tmux_path)
                ),
                None => String::new(),
            };
            out(&format!(
                "  {}{suffix}  {}{nested}",
                paint(Style::Name, &project.key),
                paint(Style::Path, &project.path)
            ));
        }
    }
    Ok(())
}

// -- add / set / remove --------------------------------------------------

pub struct AddOptions {
    pub name: String,
    pub machine: Option<String>,
    pub path: Option<String>,
    pub work: bool,
    pub session: Option<String>,
    pub tmux: Option<bool>,
    pub description: Option<String>,
    pub force: bool,
}

pub fn add(opts: AddOptions) -> Result {
    let mut registry = load()?;
    let name = opts.name;

    if registry.projects.contains_key(&name) && !opts.force {
        fail(&format!(
            "{name} is already registered (pass --force to overwrite)"
        ));
        return Err(1);
    }

    let resolved_path = mutation_path(
        &opts
            .path
            .unwrap_or_else(|| format!("{}/{name}", registry.default_dir(opts.work))),
        "project path",
    )?;

    // No machine unless you name one: every Mac holds a Syncthing mirror of
    // the directory, so where it sits says nothing about where work happens.
    let target = match &opts.machine {
        Some(machine) => Some(
            registry
                .machine(Some(machine))
                .ok_or_else(|| unknown_machine(machine))?
                .key
                .clone(),
        ),
        None => None,
    };

    let project = Project {
        key: name.clone(),
        machine: target.clone(),
        path: resolved_path.clone(),
        tmux: opts.tmux,
        session: opts.session,
        tmux_path: None,
        description: opts.description,
    };
    ensure_session_slug_available(&registry, &project, None)?;
    registry.projects.insert(name.clone(), project);
    save(&registry)?;
    let where_ = target.map(|key| format!("{key}:")).unwrap_or_default();
    out(&format!("Registered {name} -> {where_}{resolved_path}"));
    Ok(())
}

/// Fields `set --clear` can unset. `path` is absent: an entry without one
/// cannot be resolved at all.
const CLEARABLE: [&str; 5] = ["machine", "tmux", "tmux_path", "session", "description"];

pub struct SetOptions {
    pub name: String,
    pub machine: Option<String>,
    pub path: Option<String>,
    pub tmux_path: Option<String>,
    pub session: Option<String>,
    pub tmux: Option<bool>,
    pub description: Option<String>,
    pub clear: Vec<String>,
}

#[derive(Clone, PartialEq)]
enum Field {
    Str(String),
    Bool(bool),
    None,
}

impl Field {
    fn repr(&self) -> String {
        match self {
            Field::Str(value) => py_repr(value),
            Field::Bool(true) => "True".into(),
            Field::Bool(false) => "False".into(),
            Field::None => "None".into(),
        }
    }

    fn from_str(value: &Option<String>) -> Field {
        value.clone().map(Field::Str).unwrap_or(Field::None)
    }
}

fn get_field(project: &Project, field: &str) -> Field {
    match field {
        "machine" => Field::from_str(&project.machine),
        "path" => Field::Str(project.path.clone()),
        "tmux_path" => Field::from_str(&project.tmux_path),
        "session" => Field::from_str(&project.session),
        "tmux" => project.tmux.map(Field::Bool).unwrap_or(Field::None),
        "description" => Field::from_str(&project.description),
        _ => Field::None,
    }
}

fn set_field(project: &mut Project, field: &str, value: Field) {
    let as_str = |value: &Field| match value {
        Field::Str(value) => Some(value.clone()),
        _ => None,
    };
    match field {
        "machine" => project.machine = as_str(&value),
        "path" => project.path = as_str(&value).unwrap_or_default(),
        "tmux_path" => project.tmux_path = as_str(&value),
        "session" => project.session = as_str(&value),
        "tmux" => {
            project.tmux = match value {
                Field::Bool(value) => Some(value),
                _ => None,
            }
        }
        "description" => project.description = as_str(&value),
        _ => {}
    }
}

/// Edits only the fields you name, where `add --force` rewrites the entry.
pub fn set(opts: SetOptions) -> Result {
    let mut registry = load()?;
    let project = require_project(&registry, &opts.name, 1)?.clone();

    for field in &opts.clear {
        if !CLEARABLE.contains(&field.as_str()) {
            fail(&format!(
                "Cannot clear {}; try one of: {}",
                py_repr(field),
                CLEARABLE.join(", ")
            ));
            return Err(1);
        }
    }

    let mut updates: IndexMap<String, Field> = IndexMap::new();
    if let Some(machine) = &opts.machine {
        let target = registry
            .machine(Some(machine))
            .ok_or_else(|| unknown_machine(machine))?;
        updates.insert("machine".into(), Field::Str(target.key.clone()));
    }
    if let Some(path) = &opts.path {
        updates.insert(
            "path".into(),
            Field::Str(mutation_path(path, "project path")?),
        );
    }
    if let Some(tmux_path) = &opts.tmux_path {
        updates.insert(
            "tmux_path".into(),
            Field::Str(mutation_path(tmux_path, "project tmux_path")?),
        );
    }
    if let Some(session) = &opts.session {
        updates.insert("session".into(), Field::Str(session.clone()));
    }
    if let Some(tmux) = opts.tmux {
        updates.insert("tmux".into(), Field::Bool(tmux));
    }
    if let Some(description) = &opts.description {
        updates.insert("description".into(), Field::Str(description.clone()));
    }
    // Clears run last so `--session foo --clear session` is an unset.
    for field in &opts.clear {
        updates.insert(field.clone(), Field::None);
    }

    if updates.is_empty() {
        fail(&format!(
            "Nothing to change. Pass an option, or see: projects resolve {}",
            project.key
        ));
        return Err(1);
    }

    let changed: Vec<String> = updates
        .iter()
        .filter(|(field, value)| get_field(&project, field) != **value)
        .map(|(field, value)| format!("{field}={}", value.repr()))
        .collect();
    if changed.is_empty() {
        out(&format!("{} already matches; nothing written", project.key));
        return Ok(());
    }

    let mut updated = project.clone();
    for (field, value) in updates {
        set_field(&mut updated, &field, value);
    }
    updated.validate().map_err(|err| {
        fail(&err);
        2
    })?;
    ensure_session_slug_available(&registry, &updated, None)?;
    registry.projects.insert(project.key.clone(), updated);
    save(&registry)?;
    out(&format!("Updated {}: {}", project.key, changed.join(", ")));
    Ok(())
}

pub fn remove(name: &str) -> Result {
    let mut registry = load()?;
    let key = require_project(&registry, name, 1)?.key.clone();
    registry.projects.shift_remove(&key);
    save(&registry)?;
    out(&format!("Removed {key} from {}", registry.path.display()));
    Ok(())
}

// -- resolve -------------------------------------------------------------

/// `--shell` emits eval-able assignments with every value shell-quoted here,
/// so a path with a space in it survives the eval. `--machine` answers "what
/// if this project were over there?" without touching the registry.
pub fn resolve(name: &str, machine: Option<&str>, as_shell: bool, as_json: bool) -> Result {
    let registry = load()?;
    let mut project = require_project(&registry, name, 3)?.clone();

    if let Some(machine) = machine {
        let target = registry.machine(Some(machine)).ok_or_else(|| {
            fail(&format!("Unknown machine: {machine}"));
            1
        })?;
        project.machine = Some(target.key.clone());
    }

    let plan = registry.plan(&project).map_err(|err| {
        fail(&err);
        1
    })?;
    let machine_key = plan.machine.as_ref().map(|m| m.key.clone());
    let machine_host = plan.machine.as_ref().map(|m| m.host.clone());

    if as_json {
        let data = serde_json::json!({
            "name": plan.project.key,
            "machine": machine_key,
            "host": machine_host,
            "local": plan.local,
            "path": plan.path,
            "project_path": plan.project_path,
            "tmux_path": plan.project.tmux_path,
            "session": plan.session,
            "tmux": plan.tmux,
            "argv": plan.argv,
        });
        out(&serde_json::to_string_pretty(&data).unwrap_or_default());
        return Ok(());
    }

    if as_shell {
        // Expanded only for local use; the remote argv keeps its own "~" so
        // it expands against the remote home directory instead.
        let local_path = |path: &str| {
            if plan.local {
                expand_str(path)
            } else {
                path.to_string()
            }
        };
        let emit = [
            ("WORKON_RESOLVED_NAME", plan.project.key.clone()),
            (
                "WORKON_RESOLVED_KIND",
                if plan.local { "local" } else { "remote" }.into(),
            ),
            ("WORKON_RESOLVED_MACHINE", machine_key.unwrap_or_default()),
            ("WORKON_RESOLVED_HOST", machine_host.unwrap_or_default()),
            ("WORKON_RESOLVED_PATH", local_path(&plan.path)),
            (
                "WORKON_RESOLVED_PROJECT_PATH",
                local_path(&plan.project_path),
            ),
            ("WORKON_RESOLVED_SESSION", plan.session.clone()),
            (
                "WORKON_RESOLVED_TMUX",
                if plan.tmux { "1" } else { "" }.into(),
            ),
        ];
        for (key, value) in emit {
            out(&format!("{key}={}", quote(&value)));
        }
        out(&format!("WORKON_RESOLVED_ARGV=({})", join(&plan.argv)));
        return Ok(());
    }

    let where_ = match (&plan.machine, plan.local) {
        (Some(machine), false) => format!("remote via {}", machine.host),
        _ => "local".into(),
    };
    out(&format!("{}  ({where_})", plan.project.key));
    out(&format!(
        "  machine    {}",
        plan.machine
            .as_ref()
            .map(|m| m.key.as_str())
            .unwrap_or("(unset)")
    ));
    out(&format!("  path       {}", plan.project_path));
    if plan.nested() {
        out(&format!("  tmux_path  {}", plan.path));
    }
    out(&format!(
        "  session    {}{}",
        plan.session,
        if plan.tmux { "" } else { "  (tmux disabled)" }
    ));
    if !plan.argv.is_empty() {
        out(&format!("  command    {}", join(&plan.argv)));
    }
    Ok(())
}

// -- sessions ------------------------------------------------------------

pub type Probe = (Machine, std::result::Result<Vec<TmuxSession>, ProbeError>);

/// Ask every machine for its sessions at once, so one sleeping Mac costs its
/// own timeout rather than delaying every machine queued behind it.
pub fn probe_all(targets: &[Machine], timeout: u64) -> Vec<Probe> {
    thread::scope(|scope| {
        let handles: Vec<_> = targets
            .iter()
            .map(|machine| {
                scope.spawn(move || {
                    let host = (!machine.is_local()).then_some(machine.host.as_str());
                    (machine.clone(), tmux::sessions(host, timeout))
                })
            })
            .collect();
        handles
            .into_iter()
            .map(|handle| handle.join().expect("probe thread panicked"))
            .collect()
    })
}

pub fn resolve_targets(registry: &Registry, wanted: &[String]) -> Result<Vec<Machine>> {
    if wanted.is_empty() {
        return Ok(registry.machines.values().cloned().collect());
    }
    wanted
        .iter()
        .map(|name| {
            registry.machine(Some(name)).cloned().ok_or_else(|| {
                fail(&format!("Unknown machine: {name}"));
                1
            })
        })
        .collect()
}

/// The registered project a running session belongs to, if any. Path first,
/// name second: the path is where the session actually is, while its name is
/// a label that drifts.
fn project_for_session<'a>(
    registry: &'a Registry,
    machine_key: &str,
    path: &str,
    name: &str,
) -> Option<&'a Project> {
    let tilde = tildify(path);
    let mut nested: Option<&Project> = None;
    let owned_here =
        |project: &Project| project.machine.as_deref().is_none_or(|m| m == machine_key);
    for project in registry.projects.values() {
        if !owned_here(project) {
            continue;
        }
        if tilde == project.path || Some(&tilde) == project.tmux_path.as_ref() {
            return Some(project);
        }
        // Keep the deepest containing project, so a checkout nested under two
        // registered directories picks the closer one.
        if !project.path.is_empty()
            && tilde.starts_with(&format!("{}/", project.path.trim_end_matches('/')))
            && nested.is_none_or(|found| project.path.len() > found.path.len())
        {
            nested = Some(project);
        }
    }
    if nested.is_some() {
        return nested;
    }
    registry.project(name).filter(|found| owned_here(found))
}

fn confirm(prompt: &str) -> bool {
    print!("{prompt} [y/N]: ");
    let _ = std::io::stdout().flush();
    let mut answer = String::new();
    if std::io::stdin().lock().read_line(&mut answer).is_err() {
        return false;
    }
    matches!(answer.trim().to_lowercase().as_str(), "y" | "yes")
}

/// Kill the session `wanted` names -- by tmux session name or by the key of
/// the project it belongs to, slugified on both sides.
fn kill_sessions(
    registry: &Registry,
    probes: &[Probe],
    wanted: &str,
    yes: bool,
    timeout: u64,
) -> Result {
    let slug = session_slug(wanted);
    let mut matches: Vec<(&Machine, &TmuxSession, Option<&Project>, bool)> = Vec::new();
    let mut sorted: Vec<&Probe> = probes.iter().collect();
    sorted.sort_by(|a, b| a.0.key.cmp(&b.0.key));
    for (machine, result) in sorted {
        let sessions = match result {
            Ok(sessions) => sessions,
            Err(err) => {
                // Reported, not swallowed: the session being looked for might
                // be on exactly the Mac that did not answer.
                fail(&format!("{}: {err}", machine.key));
                continue;
            }
        };
        for session in sessions {
            let project = project_for_session(registry, &machine.key, &session.path, &session.name);
            let exact = wanted == session.name;
            let project_key = project.map(|p| p.key.as_str());
            if exact
                || Some(wanted) == project_key
                || slug == session_slug(&session.name)
                || project_key.is_some_and(|key| slug == session_slug(key))
            {
                matches.push((machine, session, project, exact));
            }
        }
    }

    let exact: Vec<_> = matches.iter().filter(|m| m.3).cloned().collect();
    let found = if !exact.is_empty() {
        exact
    } else {
        let mut colliding = registry.projects_for_session_slug(&slug, None);
        if colliding.len() > 1 {
            fail(&format!(
                "{} maps to the shared tmux slug {} for {} projects:",
                py_repr(wanted),
                py_repr(&slug),
                colliding.len()
            ));
            colliding.sort_by(|a, b| a.key.cmp(&b.key));
            for project in colliding {
                fail(&format!("  {}", project.key));
            }
            fail("Name the exact running tmux session instead.");
            return Err(1);
        }
        matches
    };

    if found.is_empty() {
        fail(&format!("No running session matches {}.", py_repr(wanted)));
        eprintln!("See what is live with: projects sessions");
        return Err(1);
    }

    // More than one match is ambiguous rather than an invitation to kill them
    // all.
    if found.len() > 1 {
        fail(&format!(
            "{} matches {} running sessions:",
            py_repr(wanted),
            found.len()
        ));
        for (machine, session, _, _) in &found {
            fail(&format!("  {}: {}", machine.key, session.name));
        }
        let mut machines: Vec<&str> = found.iter().map(|m| m.0.key.as_str()).collect();
        machines.sort();
        machines.dedup();
        if machines.len() > 1 {
            fail("Narrow it with --machine, or name the exact session.");
        } else {
            fail("Name the exact session to pick one.");
        }
        return Err(1);
    }

    let (machine, session, project, _) = found[0];
    let where_ = format!("{} ({})", machine.key, machine.host);
    let mut label = format!("{} on {where_}", session.name);
    if let Some(project) = project
        && project.key != session.name
    {
        label += &format!(" -- the {} project", project.key);
    }

    if machine.is_local() && env::var_os("TMUX").is_some_and(|v| !v.is_empty()) {
        warn("This is the machine you are on, and you are inside tmux right now.");
    }

    if !yes {
        let windows = if session.windows != 0 {
            format!("{} window(s), ", session.windows)
        } else {
            String::new()
        };
        let state = if session.is_attached() {
            "attached"
        } else {
            "detached"
        };
        out(&format!(
            "Kill {} on {}?",
            paint(Style::Name, &session.name),
            paint(Style::Machine, &where_)
        ));
        out(&format!(
            "  {windows}{state}, in {}",
            paint(Style::Path, &tildify(&session.path))
        ));
        if !confirm("Everything running in it goes away") {
            out(&paint(Style::Muted, "Left alone."));
            return Err(1);
        }
    }

    let host = (!machine.is_local()).then_some(machine.host.as_str());
    if let Err(err) = tmux::kill_session(&session.name, host, timeout) {
        fail(&format!("Could not kill {label}: {err}"));
        return Err(1);
    }
    out(&format!(
        "Killed {} on {}",
        paint(Style::Name, &session.name),
        paint(Style::Machine, &where_)
    ));
    Ok(())
}

/// Show the tmux sessions running on every Mac, and what to type to reach one.
pub fn sessions(
    machines: &[String],
    attached: bool,
    names: bool,
    kill: Option<&str>,
    yes: bool,
    timeout: u64,
) -> Result {
    let registry = load()?;
    if registry.machines.is_empty() {
        fail("No machines configured; run `projects init` first.");
        return Err(1);
    }
    let targets = resolve_targets(&registry, machines)?;
    let probes = probe_all(&targets, timeout);

    if let Some(wanted) = kill {
        return kill_sessions(&registry, &probes, wanted, yes, timeout);
    }

    let mut total = 0;
    let mut unregistered = 0;
    let mut sorted: Vec<&Probe> = probes.iter().collect();
    sorted.sort_by(|a, b| a.0.key.cmp(&b.0.key));
    for (machine, result) in sorted {
        let found = match result {
            Ok(found) => found,
            Err(err) => {
                // stderr, so --names stays pipeable while unreachable Macs
                // stay visible.
                fail(&format!("{}: {err}", machine.key));
                continue;
            }
        };
        let mut listed: Vec<&TmuxSession> = found
            .iter()
            .filter(|s| s.is_attached() || !attached)
            .collect();
        if listed.is_empty() {
            continue;
        }
        total += listed.len();

        if !names {
            let local_mark = if machine.is_local() {
                format!(" {}", paint(Style::Muted, "(this machine)"))
            } else {
                String::new()
            };
            out(&format!(
                "{} {}{local_mark}",
                paint(Style::Machine, &machine.key),
                paint(Style::Muted, &format!("({})", machine.host))
            ));
        }

        listed.sort_by(|a, b| a.name.cmp(&b.name));
        for session in listed {
            let project =
                project_for_session(&registry, &machine.key, &session.path, &session.name);
            if names {
                // Only registered projects: a name workon cannot open is
                // worse than absent.
                if let Some(project) = project {
                    out(&project.key);
                }
                continue;
            }
            let (state, style) = if session.is_attached() {
                ("attached", Style::ReasonSession)
            } else {
                ("detached", Style::Muted)
            };
            let windows = if session.windows != 0 {
                format!("{}w", session.windows)
            } else {
                String::new()
            };
            let reach = match project {
                Some(project) => paint(Style::Name, &format!("workon {}", project.key)),
                None => {
                    unregistered += 1;
                    format!(
                        "{} {}",
                        paint(Style::Path, &tildify(&session.path)),
                        paint(Style::Warn, "(not registered)")
                    )
                }
            };
            out(&format!(
                "  {:<38} {} {windows:<4} {reach}",
                session.name,
                paint(style, &format!("{state:<8}"))
            ));
        }
    }

    if names {
        return Ok(());
    }
    if total == 0 {
        out(&paint(Style::Muted, "No tmux sessions running anywhere."));
        return Ok(());
    }
    let mut summary = format!("\n{}", paint(Style::Name, &format!("{total} session(s)")));
    if unregistered > 0 {
        summary += &format!(
            ", {} {}",
            paint(
                Style::Warn,
                &format!("{unregistered} with no registered project")
            ),
            paint(Style::Muted, "(projects add <name> to fix)")
        );
    }
    out(&summary);
    Ok(())
}

// -- create --------------------------------------------------------------

/// The .envrc a new project gets: `layout uv`, plus `use tmux` unless the
/// project opted out of a session.
fn envrc_contents(name: &str, tmux: bool) -> String {
    if !tmux {
        return "layout uv\n".into();
    }
    format!("layout uv\nuse tmux {}\n", quote(name))
}

/// Shell that creates the project directory, its venv, and its .envrc. Each
/// step is guarded, so re-running on a half-made project finishes it.
fn create_script(path: &str, name: &str, python: &str, tmux: bool) -> String {
    let path_expr = remote_path_expr(path);
    let envrc = envrc_contents(name, tmux);
    [
        "set -e".to_string(),
        format!("mkdir -p {path_expr}"),
        format!("cd {path_expr}"),
        format!("[ -d .venv ] || uv venv --python {} .venv", quote(python)),
        format!("[ -f .envrc ] || printf %s {} > .envrc", quote(&envrc)),
        "command -v direnv >/dev/null 2>&1 && direnv allow . || true".to_string(),
        format!("echo created {path_expr}"),
    ]
    .join("\n")
}

pub struct CreateOptions {
    pub name: String,
    pub machine: Option<String>,
    pub path: Option<String>,
    pub work: bool,
    pub session: Option<String>,
    pub tmux: Option<bool>,
    pub python: String,
    pub dry_run: bool,
}

/// Always creates here, even for a project registered to another machine:
/// ~/Projects and ~/Work are Syncthing folders, so the directory arrives on
/// its own, and `layout uv` builds a native venv over there on first entry.
pub fn create(opts: CreateOptions) -> Result {
    let mut registry = load()?;
    let name = opts.name;

    let resolved_path = mutation_path(
        &opts
            .path
            .unwrap_or_else(|| format!("{}/{name}", registry.default_dir(opts.work))),
        "project path",
    )?;

    let target = match &opts.machine {
        Some(machine) => Some(
            registry
                .machine(Some(machine))
                .ok_or_else(|| unknown_machine(machine))?
                .key
                .clone(),
        ),
        None => None,
    };

    if registry.projects.contains_key(&name) {
        fail(&format!(
            "{name} is already registered; remove it first or pick another name"
        ));
        return Err(1);
    }

    let want_tmux = opts.tmux.unwrap_or_else(|| registry.tmux_default());
    let session_name = opts.session.clone().unwrap_or_else(|| session_slug(&name));
    let project = Project {
        key: name.clone(),
        machine: target.clone(),
        path: resolved_path.clone(),
        tmux: opts.tmux,
        session: opts.session,
        tmux_path: None,
        description: None,
    };
    ensure_session_slug_available(&registry, &project, None)?;
    let script = create_script(&resolved_path, &session_name, &opts.python, want_tmux);
    let argv = ["bash", "-lc", &script];
    let where_ = target.map(|key| format!("{key}:")).unwrap_or_default();

    if opts.dry_run {
        out(&join(&argv));
        out(&format!(
            "# then register {name} -> {where_}{resolved_path}"
        ));
        return Ok(());
    }

    out(&format!("Creating {resolved_path}"));
    let status = Command::new("bash").args(&argv[1..]).status();
    match status {
        Ok(status) if status.success() => {}
        Ok(status) => {
            fail(&format!("Creation failed; not registering {name}"));
            return Err(status.code().unwrap_or(1));
        }
        Err(err) => {
            fail(&format!("Creation failed ({err}); not registering {name}"));
            return Err(1);
        }
    }

    registry.projects.insert(name.clone(), project);
    save(&registry)?;
    out(&format!("Registered {name} -> {where_}{resolved_path}"));
    Ok(())
}

// -- edit / init ---------------------------------------------------------

pub fn edit() -> Result {
    let registry = load()?;
    if !registry.path.is_file() {
        fail(&format!(
            "No registry at {} (run `projects init` first)",
            registry.path.display()
        ));
        return Err(1);
    }
    let editor = env::var("EDITOR")
        .ok()
        .filter(|v| !v.is_empty())
        .or_else(|| env::var("VISUAL").ok().filter(|v| !v.is_empty()));
    let Some(editor) = editor else {
        fail("Set $EDITOR (or $VISUAL) to open the registry");
        return Err(1);
    };
    let argv = crate::util::split(&editor);
    let Some((program, args)) = argv.split_first() else {
        fail("Set $EDITOR (or $VISUAL) to open the registry");
        return Err(1);
    };
    match Command::new(program)
        .args(args)
        .arg(&registry.path)
        .status()
    {
        Ok(status) if status.success() => Ok(()),
        Ok(status) => Err(status.code().unwrap_or(1)),
        Err(err) => {
            fail(&format!("Could not run {editor}: {err}"));
            Err(1)
        }
    }
}

/// Machines listed in ~/.config/cmux-tmux/hosts.toml, keyed by the first
/// dotted component of each ssh name.
fn machines_from_hosts_toml(path: &std::path::Path) -> std::result::Result<Vec<Machine>, String> {
    let text = std::fs::read_to_string(path).map_err(|err| err.to_string())?;
    let doc: DocumentMut = text
        .parse()
        .map_err(|err: toml_edit::TomlError| err.to_string())?;
    let aliases = doc.get("aliases").and_then(Item::as_table_like);
    let hosts = doc.get("hosts").and_then(Item::as_array);
    Ok(hosts
        .map(|hosts| {
            hosts
                .iter()
                .filter_map(Value::as_str)
                .map(|host| Machine {
                    key: host.split('.').next().unwrap_or(host).to_string(),
                    host: host.to_string(),
                    hostname: aliases
                        .and_then(|a| a.get(host))
                        .and_then(Item::as_str)
                        .map(String::from),
                })
                .collect()
        })
        .unwrap_or_default())
}

/// Create the registry, importing machines from hosts.toml if it exists.
pub fn init(force: bool) -> Result {
    let mut registry = load()?;
    if registry.path.is_file() && !registry.machines.is_empty() && !force {
        fail(&format!(
            "{} already has machines (pass --force to re-import)",
            registry.path.display()
        ));
        return Err(1);
    }

    let hosts_toml = cmux_config_dir().join("hosts.toml");
    let mut rebuilt: IndexMap<String, Machine> = IndexMap::new();
    let mut imported = 0;
    if hosts_toml.is_file() {
        let machines = machines_from_hosts_toml(&hosts_toml).map_err(|err| {
            fail(&format!("Could not read {}: {err}", hosts_toml.display()));
            2
        })?;
        for machine in machines {
            rebuilt.insert(machine.key.clone(), machine);
            imported += 1;
        }
    }

    if rebuilt.is_empty() {
        let mut names = local_hostnames();
        names.sort();
        let hostname = names.into_iter().next().unwrap_or_default();
        rebuilt.insert(
            hostname.clone(),
            Machine {
                key: hostname.clone(),
                host: hostname.clone(),
                hostname: None,
            },
        );
        out(&format!(
            "No hosts.toml found; seeded [machines] with this machine ({hostname})."
        ));
    }

    let old_machines = std::mem::replace(&mut registry.machines, rebuilt);

    let mut remapped = Vec::new();
    let mut cleared = Vec::new();
    if force {
        for project in registry.projects.values_mut() {
            let Some(current) = project.machine.clone() else {
                continue;
            };
            if registry.machines.contains_key(&current) {
                continue;
            }
            let matches: Vec<&Machine> = match old_machines.get(&current) {
                Some(old) => registry
                    .machines
                    .values()
                    .filter(|m| m.host.to_lowercase() == old.host.to_lowercase())
                    .collect(),
                None => Vec::new(),
            };
            let new_machine = (matches.len() == 1).then(|| matches[0].key.clone());
            match &new_machine {
                Some(new) => remapped.push(format!("{}: {current} -> {new}", project.key)),
                None => cleared.push(format!("{}: {current}", project.key)),
            }
            project.machine = new_machine;
        }
    }

    let home_dir = registry.home_dir();
    let work_dir = registry.work_dir();
    registry
        .defaults
        .entry("tmux".into())
        .or_insert(Value::from(false));
    registry
        .defaults
        .entry("home_dir".into())
        .or_insert(Value::from(home_dir));
    registry
        .defaults
        .entry("work_dir".into())
        .or_insert(Value::from(work_dir));

    save(&registry)?;
    if imported > 0 {
        out(&format!(
            "Imported {imported} machines from {}",
            hosts_toml.display()
        ));
    }
    if !remapped.is_empty() {
        out(&format!(
            "Remapped {} project machine reference(s).",
            remapped.len()
        ));
    }
    if !cleared.is_empty() {
        let more = if cleared.len() > 5 { " ..." } else { "" };
        warn(&format!(
            "Cleared removed machine references from {} project(s): {}{more}",
            cleared.len(),
            cleared[..cleared.len().min(5)].join(", ")
        ));
    }
    out(&format!("Wrote {}", registry.path.display()));
    out("Next: rename the machine keys if you want shorter ones, then");
    out("`projects import --dry-run`.");
    Ok(())
}

// -- machines ------------------------------------------------------------

pub fn machines_list() -> Result {
    let registry = load()?;
    if registry.machines.is_empty() {
        out(&format!(
            "No machines configured in {}",
            registry.path.display()
        ));
        return Ok(());
    }
    let mut keys: Vec<&String> = registry.machines.keys().collect();
    keys.sort();
    for key in keys {
        let machine = &registry.machines[key];
        let mut marks = Vec::new();
        if machine.is_local() {
            marks.push("this machine".to_string());
        }
        if let Some(hostname) = &machine.hostname {
            marks.push(format!("hostname {hostname}"));
        }
        let count = registry
            .projects
            .values()
            .filter(|p| {
                registry
                    .machine(p.machine.as_deref())
                    .is_some_and(|m| m.key == machine.key)
            })
            .count();
        marks.push(format!(
            "{count} project{}",
            if count == 1 { "" } else { "s" }
        ));
        out(&format!(
            "{key}  ({})  [{}]",
            machine.host,
            marks.join(", ")
        ));
    }
    Ok(())
}

fn reachable(host: &str) -> bool {
    let argv = [
        "ssh",
        "-o",
        "BatchMode=yes",
        "-o",
        "ConnectTimeout=5",
        host,
        "true",
    ]
    .map(String::from);
    run_captured(&argv, Some(std::time::Duration::from_secs(30)))
        .is_ok_and(|output| output.status.success())
}

pub fn machines_add(
    key: &str,
    host: Option<String>,
    hostname: Option<String>,
    check: bool,
) -> Result {
    let mut registry = load()?;
    if registry.machines.contains_key(key) {
        fail(&format!("{key} is already configured"));
        return Err(1);
    }
    let machine = Machine {
        key: key.to_string(),
        host: host.unwrap_or_else(|| key.to_string()),
        hostname: hostname.clone(),
    };
    if check && !reachable(&machine.host) {
        fail(&format!(
            "{} did not answer over ssh; not added (drop --check to add anyway)",
            machine.host
        ));
        return Err(1);
    }
    registry.machines.insert(key.to_string(), machine.clone());
    save(&registry)?;
    let note = hostname
        .as_ref()
        .map(|h| format!(" (hostname {h})"))
        .unwrap_or_default();
    out(&format!("Added {key} -> {}{note}", machine.host));

    // Without `hostname`, a Mac whose own hostname differs from its ssh name
    // is never recognized as local and gets dialed over the network from
    // itself.
    if hostname.is_none() && !machine.is_local() {
        warn(&format!(
            "If {} reports a different hostname to itself, re-add it with \
             --hostname so this machine is skipped when you run there.",
            machine.host
        ));
    }
    Ok(())
}

pub fn machines_remove(key: &str) -> Result {
    let mut registry = load()?;
    if !registry.machines.contains_key(key) {
        fail(&format!("{key} is not configured"));
        return Err(1);
    }
    let mut holders: Vec<&str> = registry
        .projects
        .values()
        .filter(|p| p.machine.as_deref() == Some(key))
        .map(|p| p.key.as_str())
        .collect();
    if !holders.is_empty() {
        holders.sort();
        let more = if holders.len() > 5 { " ..." } else { "" };
        fail(&format!(
            "{key} still holds {} project(s): {}{more}",
            holders.len(),
            holders[..holders.len().min(5)].join(", ")
        ));
        fail("Move or remove them first.");
        return Err(1);
    }
    registry.machines.shift_remove(key);
    save(&registry)?;
    out(&format!("Removed {key} from {}", registry.path.display()));
    Ok(())
}
