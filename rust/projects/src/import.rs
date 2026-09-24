//! `projects import`: register ~/Projects and ~/Work from evidence.
//!
//! The machine comes from evidence or not at all. A running tmux session is
//! the strongest signal, followed by a host pinned in the cmux session dump. A
//! directory with neither is registered with no machine, which means
//! "wherever you are" -- the roots are Syncthing-mirrored, so a directory's
//! presence says nothing about where the work happens.

use std::collections::{BTreeMap, BTreeSet, HashSet};
use std::fs;
use std::path::Path;

use clap::Args;
use indexmap::IndexMap;

use crate::commands::{
    Result, ensure_session_slug_available, load, out, probe_all, resolve_targets,
};
use crate::registry::{Machine, Project, Registry};
use crate::tmux::{TmuxSession, Workspace, default_dump_path, load_dump};
use crate::util::{Style, expand, fail, paint, session_slug, tildify, warn};

#[derive(Args)]
pub struct ImportArgs {
    /// Show what would be registered
    #[arg(long = "dry-run", short = 'n')]
    dry_run: bool,
    /// Only probe these machines (repeatable)
    #[arg(long, short)]
    machine: Vec<String>,
    /// Skip the tmux probe; register directories only
    #[arg(long = "no-sessions")]
    no_sessions: bool,
    /// Register only projects with real evidence
    #[arg(long = "sessions-only")]
    sessions_only: bool,
    /// ssh connect timeout in seconds
    #[arg(long, short, default_value_t = 5)]
    timeout: u64,
    /// Also re-assign projects already registered
    #[arg(long, short)]
    force: bool,
}

impl ImportArgs {
    pub fn dry_run(dry_run: bool) -> ImportArgs {
        ImportArgs {
            dry_run,
            machine: Vec::new(),
            no_sessions: false,
            sessions_only: false,
            timeout: 5,
            force: false,
        }
    }
}

/// Prefix for a ~/Work project whose name is also taken under ~/Projects.
const WORK_PREFIX: &str = "work-";

/// One proposed registry entry, plus how its machine was decided.
#[derive(Clone)]
struct Candidate {
    name: String,
    machine: Option<String>,
    path: String,
    reason: &'static str,
    session: Option<String>,
    tmux_path: Option<String>,
}

impl Candidate {
    /// Best evidence first: a live attached session, an idle one, a cmux
    /// workspace pin, then a directory that merely exists.
    fn rank(&self) -> u8 {
        match self.reason {
            "session" => 0,
            "session-idle" => 1,
            "workspace" => 2,
            _ => 3,
        }
    }
}

fn dir_names(root_dir: &str) -> HashSet<String> {
    let Ok(entries) = fs::read_dir(expand(root_dir)) else {
        return HashSet::new();
    };
    entries
        .flatten()
        .filter(|entry| entry.path().is_dir())
        .map(|entry| entry.file_name().to_string_lossy().into_owned())
        .filter(|name| !name.starts_with('.'))
        .collect()
}

/// Names that exist under both roots, and so need disambiguating.
fn work_collisions(registry: &Registry) -> HashSet<String> {
    if expand(&registry.home_dir()) == expand(&registry.work_dir()) {
        return HashSet::new();
    }
    let home = dir_names(&registry.home_dir());
    let work = dir_names(&registry.work_dir());
    home.intersection(&work).cloned().collect()
}

/// The registry key for a directory, disambiguating Work against Projects.
fn project_key(
    registry: &Registry,
    root_dir: &str,
    name: &str,
    collisions: &HashSet<String>,
) -> String {
    if expand(root_dir) == expand(&registry.work_dir()) && collisions.contains(name) {
        return format!("{WORK_PREFIX}{name}");
    }
    name.to_string()
}

/// The top-level directory name under `root`, or None if not under it.
/// Matched on the root's basename, because a session path comes from a remote
/// host whose home directory we have not resolved.
fn project_under_root(path: &str, root: &str) -> Option<String> {
    let base = Path::new(root).file_name()?.to_string_lossy();
    let marker = format!("/{}/", base.trim_matches('/'));
    let index = path.find(&marker)?;
    let remainder = &path[index + marker.len()..];
    let name = remainder.split('/').next().unwrap_or("");
    (!name.is_empty()).then(|| name.to_string())
}

/// The project a path belongs to under either root, as (key, project path).
fn under_roots(
    registry: &Registry,
    path: &str,
    collisions: &HashSet<String>,
) -> Option<(String, String)> {
    for root in [registry.home_dir(), registry.work_dir()] {
        if let Some(name) = project_under_root(path, &root) {
            let project_path = format!("{root}/{name}");
            return Some((
                project_key(registry, &root, &name, collisions),
                project_path,
            ));
        }
    }
    None
}

/// Turn one machine's running tmux sessions into candidates. The session's
/// own directory goes to `tmux_path` when it differs from the project root.
fn candidates_from_sessions(
    registry: &Registry,
    machine: &Machine,
    sessions: &[TmuxSession],
    collisions: &HashSet<String>,
) -> Vec<Candidate> {
    sessions
        .iter()
        .map(|session| {
            let session_path = tildify(&session.path);
            // A session outside both roots is still real work; register it
            // under its own name, with the session path as the path.
            let (name, project_path) = under_roots(registry, &session.path, collisions)
                .unwrap_or_else(|| (session.name.clone(), session_path.clone()));
            Candidate {
                name,
                machine: Some(machine.key.clone()),
                reason: if session.is_attached() {
                    "session"
                } else {
                    "session-idle"
                },
                session: Some(session.name.clone()),
                tmux_path: (session_path != project_path).then_some(session_path),
                path: project_path,
            }
        })
        .collect()
}

/// Normalize a name so a workspace title ("djangotv-com-git") matches the
/// directory it refers to ("djangotv.com").
fn hint_key(name: &str) -> String {
    let key = session_slug(name);
    match key.strip_suffix("-git") {
        Some(stripped) => stripped.to_string(),
        None => key,
    }
}

type Hints = BTreeMap<String, BTreeSet<String>>;

/// Machine assignments recorded in the cmux session dump: full candidates,
/// plus machine-only hints for remote workspaces whose `cwd` is deliberately
/// the *local* home directory and so says nothing about the path.
fn candidates_from_dump(
    registry: &Registry,
    collisions: &HashSet<String>,
) -> (Vec<Candidate>, Hints) {
    let path = default_dump_path();
    let mut found = Vec::new();
    let mut hints = Hints::new();
    if !path.is_file() {
        return (found, hints);
    }
    let Ok(entries) = load_dump(&path) else {
        return (found, hints);
    };

    for workspace in entries {
        let Workspace {
            host: Some(host), ..
        } = &workspace
        else {
            continue;
        };
        let Some(machine) = registry.machine(Some(host)) else {
            continue;
        };
        match under_roots(registry, &workspace.cwd, collisions) {
            Some((name, project_path)) => {
                let workspace_path = tildify(&workspace.cwd);
                found.push(Candidate {
                    name,
                    machine: Some(machine.key.clone()),
                    reason: "workspace",
                    session: Some(workspace.session_name()),
                    tmux_path: (workspace_path != project_path).then_some(workspace_path),
                    path: project_path,
                });
            }
            None => {
                hints
                    .entry(hint_key(workspace.base_title()))
                    .or_default()
                    .insert(machine.key.clone());
            }
        }
    }
    (found, hints)
}

/// Every directory under home_dir and work_dir, with no machine claimed.
fn candidates_from_dirs(registry: &Registry, collisions: &HashSet<String>) -> Vec<Candidate> {
    let mut found = Vec::new();
    for root_dir in [registry.home_dir(), registry.work_dir()] {
        let root = expand(&root_dir);
        let Ok(entries) = fs::read_dir(&root) else {
            warn(&format!(
                "{root_dir} does not exist; nothing to import from it"
            ));
            continue;
        };
        let mut names: Vec<String> = entries
            .flatten()
            .filter(|entry| entry.path().is_dir())
            .map(|entry| entry.file_name().to_string_lossy().into_owned())
            .filter(|name| !name.starts_with('.'))
            .collect();
        names.sort();
        for name in names {
            found.push(Candidate {
                name: project_key(registry, &root_dir, &name, collisions),
                machine: None,
                path: format!("{root_dir}/{name}"),
                reason: "default",
                session: None,
                tmux_path: None,
            });
        }
    }
    found
}

/// Reject equal-best evidence that points one project at multiple Macs.
fn reject_conflicting_evidence(candidates: &[Candidate]) -> Result {
    let mut by_name: IndexMap<&str, Vec<&Candidate>> = IndexMap::new();
    for candidate in candidates {
        by_name.entry(&candidate.name).or_default().push(candidate);
    }
    let mut conflicts = Vec::new();
    for (name, found) in by_name {
        let best = found.iter().map(|c| c.rank()).min().unwrap_or(3);
        let strongest: Vec<&&Candidate> = found.iter().filter(|c| c.rank() == best).collect();
        let machines: BTreeSet<&str> = strongest
            .iter()
            .filter_map(|c| c.machine.as_deref())
            .collect();
        if machines.len() > 1 {
            let mut details: Vec<String> = strongest
                .iter()
                .filter_map(|c| {
                    c.machine
                        .as_ref()
                        .map(|m| format!("{m}:{} ({})", c.path, c.reason))
                })
                .collect();
            details.sort();
            conflicts.push(format!("{name}: {}", details.join(", ")));
        }
    }
    if conflicts.is_empty() {
        return Ok(());
    }
    fail("Conflicting equal-rank import evidence:");
    for conflict in conflicts {
        fail(&format!("  {conflict}"));
    }
    fail("Narrow the import with --machine or resolve the duplicate evidence.");
    Err(1)
}

/// Pinned only when it differs from what the key would slug to.
fn pinned_session(candidate: &Candidate, name: &str) -> Option<String> {
    candidate
        .session
        .clone()
        .filter(|session| !session.is_empty() && *session != session_slug(name))
}

pub fn run(args: &ImportArgs) -> Result {
    let mut registry = load()?;
    if registry.machines.is_empty() {
        fail("No machines configured; run `projects init` first.");
        return Err(1);
    }
    let targets = resolve_targets(&registry, &args.machine)?;

    let mut candidates: Vec<Candidate> = Vec::new();
    let mut hints = Hints::new();
    let collisions = work_collisions(&registry);
    if !collisions.is_empty() {
        out(&format!(
            "{} {}",
            paint(
                Style::Muted,
                &format!(
                    "{} name(s) exist under both roots; the ~/Work copy is keyed",
                    collisions.len()
                )
            ),
            paint(Style::Name, &format!("{WORK_PREFIX}<name>"))
        ));
    }

    if !args.no_sessions {
        out(&paint(
            Style::Muted,
            &format!("Probing {} machine(s) for tmux sessions...", targets.len()),
        ));
        for (machine, result) in probe_all(&targets, args.timeout) {
            match result {
                Err(err) => fail(&format!("  {}: error: {err}", machine.key)),
                Ok(sessions) => {
                    let style = if sessions.is_empty() {
                        Style::Muted
                    } else {
                        Style::ReasonSession
                    };
                    out(&format!(
                        "  {}: {}",
                        paint(Style::Machine, &machine.key),
                        paint(style, &format!("{} session(s)", sessions.len()))
                    ));
                    candidates.extend(candidates_from_sessions(
                        &registry,
                        &machine,
                        &sessions,
                        &collisions,
                    ));
                }
            }
        }
        let (dump_candidates, dump_hints) = candidates_from_dump(&registry, &collisions);
        candidates.extend(dump_candidates);
        hints = dump_hints;
    }

    if !args.sessions_only {
        candidates.extend(candidates_from_dirs(&registry, &collisions));
    }

    reject_conflicting_evidence(&candidates)?;
    for candidate in &candidates {
        if candidate.reason == "workspace"
            && let Some(machine) = &candidate.machine
        {
            hints
                .entry(hint_key(&candidate.name))
                .or_default()
                .insert(machine.clone());
        }
    }
    let conflicting: Vec<(&String, &BTreeSet<String>)> = hints
        .iter()
        .filter(|(_, machines)| machines.len() > 1)
        .collect();
    if !conflicting.is_empty() {
        fail("Conflicting equal-rank workspace hints:");
        for (name, machines) in conflicting {
            let machines: Vec<&str> = machines.iter().map(String::as_str).collect();
            fail(&format!("  {name}: {}", machines.join(", ")));
        }
        fail("Narrow the import with --machine or fix the cmux dump.");
        return Err(1);
    }

    // Keep the best-ranked candidate per project: sorted by rank, first one
    // wins, so a live session always displaces the bare directory.
    let mut order: Vec<usize> = (0..candidates.len()).collect();
    order.sort_by(|&a, &b| {
        let (a, b) = (&candidates[a], &candidates[b]);
        (a.rank(), a.machine.as_deref().unwrap_or(""))
            .cmp(&(b.rank(), b.machine.as_deref().unwrap_or("")))
    });
    let mut best: IndexMap<String, usize> = IndexMap::new();
    for index in order {
        best.entry(candidates[index].name.clone()).or_insert(index);
    }

    // A session outside the roots is keyed by its session name, which can
    // collide with an unrelated directory of that name. The session wins, but
    // a silent merge of two different trees is worth saying out loud.
    let mut name_collisions = Vec::new();
    for (index, candidate) in candidates.iter().enumerate() {
        if candidate.reason != "default" {
            continue;
        }
        let Some(&winner_index) = best.get(&candidate.name) else {
            continue;
        };
        let winner = &candidates[winner_index];
        if winner_index == index || winner.path == candidate.path {
            continue;
        }
        // Nested checkouts (project/project-git) are the same project.
        if winner.path.starts_with(&format!("{}/", candidate.path)) {
            continue;
        }
        name_collisions.push((
            candidate.name.clone(),
            candidate.path.clone(),
            winner.path.clone(),
        ));
    }

    // Machine-only hints from the dump: an entry with no machine that cmux
    // pins to one takes that machine and keeps its own path.
    for (name, &index) in &best {
        if candidates[index].reason != "default" {
            continue;
        }
        if let Some(machine) = hints.get(&hint_key(name)).and_then(|m| m.iter().next()) {
            candidates[index].machine = Some(machine.clone());
            candidates[index].reason = "workspace";
        }
    }

    let mut planned = registry.projects.clone();
    let mut proposals: IndexMap<String, Project> = IndexMap::new();
    for (name, &index) in &best {
        let candidate = &candidates[index];
        let existing = registry.projects.get(name);
        if existing.is_some() && (!args.force || candidate.reason == "default") {
            continue;
        }
        // `tmux` and `description` are carried over when set; a running
        // session turns an unset `tmux` on, and never overrides an explicit
        // one.
        let mut tmux = existing.and_then(|p| p.tmux);
        if tmux.is_none() && matches!(candidate.reason, "session" | "session-idle") {
            tmux = Some(true);
        }
        let proposal = Project {
            key: name.clone(),
            machine: candidate.machine.clone(),
            path: candidate.path.clone(),
            tmux_path: candidate.tmux_path.clone(),
            session: pinned_session(candidate, name),
            tmux,
            description: existing.and_then(|p| p.description.clone()),
        };
        planned.insert(name.clone(), proposal.clone());
        proposals.insert(name.clone(), proposal);
    }
    for proposal in proposals.values() {
        ensure_session_slug_available(&registry, proposal, Some(&planned))?;
    }

    let (mut added, mut updated, mut skipped, mut evidence) = (0, 0, 0, 0);
    let mut names: Vec<&String> = best.keys().collect();
    names.sort();
    let mut writes: Vec<(String, Project)> = Vec::new();

    for name in names {
        let candidate = &candidates[best[name]];
        let existing = registry.projects.get(name);
        let candidate_session = pinned_session(candidate, name);

        let note = match existing {
            Some(existing) => {
                // --force promotes evidence; it does not erase it. A
                // "default" candidate knows only that a directory exists, and
                // letting it write would strip what a session put there.
                if !args.force || candidate.reason == "default" {
                    skipped += 1;
                    continue;
                }
                let mut changes = Vec::new();
                if existing.machine != candidate.machine {
                    changes.push(format!(
                        "machine {} -> {}",
                        existing.machine.as_deref().unwrap_or("unset"),
                        candidate.machine.as_deref().unwrap_or("unset")
                    ));
                }
                if existing.path != candidate.path {
                    changes.push(format!("path {} -> {}", existing.path, candidate.path));
                }
                if existing.tmux_path != candidate.tmux_path {
                    changes.push(format!(
                        "tmux_path {} -> {}",
                        existing.tmux_path.as_deref().unwrap_or("-"),
                        candidate.tmux_path.as_deref().unwrap_or("-")
                    ));
                }
                if existing.session != candidate_session {
                    changes.push(format!(
                        "session {} -> {}",
                        existing.session.as_deref().unwrap_or("-"),
                        candidate_session.as_deref().unwrap_or("-")
                    ));
                }
                if changes.is_empty() {
                    skipped += 1;
                    continue;
                }
                format!(" ({}; {})", changes.join("; "), candidate.reason)
            }
            None => format!(" ({})", candidate.reason),
        };

        if candidate.reason != "default" {
            evidence += 1;
        }

        let mut extra = String::new();
        if let Some(tmux_path) = &candidate.tmux_path {
            extra += &format!(
                " {}",
                paint(Style::Extra, &format!("+tmux_path={tmux_path}"))
            );
        }
        if let Some(session) = &candidate_session {
            extra += &format!(
                " {}",
                paint(Style::Extra, &format!("+tmux_session={session}"))
            );
        }
        let where_ = match &candidate.machine {
            Some(machine) => format!("{}:", paint(Style::Machine, machine)),
            None => String::new(),
        };
        let (label, style) = if args.dry_run {
            ("would", Style::Would)
        } else if existing.is_some() {
            ("update", Style::Update)
        } else {
            ("add", Style::Add)
        };
        out(&format!(
            "{} {} {} {where_}{}{extra} {}",
            paint(style, &format!("{label:<6}")),
            paint(Style::Name, name),
            paint(Style::Muted, "->"),
            paint(Style::Path, &candidate.path),
            paint(Style::for_reason(candidate.reason), &note)
        ));

        if !args.dry_run {
            writes.push((name.clone(), proposals[name].clone()));
        }
        if existing.is_some() {
            updated += 1;
        } else {
            added += 1;
        }
    }
    for (name, project) in writes {
        registry.projects.insert(name, project);
    }

    if !name_collisions.is_empty() {
        out(&format!(
            "\n{}",
            paint(
                Style::Warn,
                "Name collisions (the session won; rename by hand if wrong):"
            )
        ));
        for (name, dropped, kept) in name_collisions {
            out(&format!(
                "  {}: kept {}, {} {}",
                paint(Style::Name, &name),
                paint(Style::Path, &kept),
                paint(Style::Muted, "dropped"),
                paint(Style::Path, &dropped)
            ));
        }
    }

    let total = added + updated;
    if total == 0 {
        out(&format!(
            "\n{}",
            paint(
                Style::Muted,
                &format!("Nothing to import ({skipped} already registered)")
            )
        ));
        return Ok(());
    }

    let summary = format!(
        "{}: {}, {}, {}. {}, {}.",
        paint(Style::Name, &format!("{total} project(s)")),
        paint(Style::Add, &format!("{added} new")),
        paint(Style::Update, &format!("{updated} re-assigned")),
        paint(Style::Muted, &format!("{skipped} unchanged")),
        paint(
            Style::ReasonSession,
            &format!("{evidence} backed by a session or workspace")
        ),
        paint(
            Style::ReasonDefault,
            &format!("{} with no machine", total - evidence)
        ),
    );
    if args.dry_run {
        out(&format!("\n{summary}"));
        out(&paint(Style::Muted, "Re-run without --dry-run to apply."));
        return Ok(());
    }

    registry.save().map_err(|err| {
        fail(&format!(
            "Could not write {}: {err}",
            registry.path.display()
        ));
        1
    })?;
    out(&format!("\n{summary}"));
    out(&format!(
        "{} {}",
        paint(Style::Add, "Wrote"),
        paint(Style::Path, &registry.path.display().to_string())
    ));
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn project_under_root_takes_first_component() {
        assert_eq!(
            project_under_root(
                "/Users/x/Projects/django-news.com/django-news.com-git",
                "~/Projects"
            ),
            Some("django-news.com".into())
        );
        assert_eq!(project_under_root("/Users/x/Projects/", "~/Projects"), None);
        assert_eq!(project_under_root("/Users/x/elsewhere", "~/Projects"), None);
    }

    #[test]
    fn hint_key_drops_git_suffix() {
        assert_eq!(hint_key("djangotv.com-git"), "djangotv-com");
        assert_eq!(hint_key("djangotv.com"), "djangotv-com");
    }
}
