//! The project registry in ~/Projects/projects.toml.
//!
//! A port of ~/bin/_projects.py. The registry answers one question: given a
//! project name, which machine is it on, where does it live there, and what
//! tmux session holds it. The file format is unchanged, so this and the
//! Python `projects-archive` can read and write the same registry side by side.

use std::env;
use std::fs::{self, File, OpenOptions};
use std::io::Write;
use std::os::fd::AsRawFd;
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};

use indexmap::IndexMap;
use toml_edit::{DocumentMut, Item, Key, Table, Value};

use crate::util::{
    expand, local_hostnames, py_repr, quote, remote_path_expr, session_slug, validate_path, which,
};

pub const NEW_FILE_HEADER: &str = "\
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
";

/// ~/Projects/projects.toml, or $PROJECTS_TOML for a single run or for tests.
pub fn registry_path() -> Result<PathBuf, String> {
    let override_ = env::var("PROJECTS_TOML").unwrap_or_default();
    let override_ = override_.trim();
    if override_.is_empty() {
        return Ok(crate::util::home().join("Projects").join("projects.toml"));
    }
    validate_path(override_, "PROJECTS_TOML")?;
    Ok(expand(override_))
}

/// Serialize a complete registry load-modify-save transaction. Same lock file
/// as the Python side, so the two implementations exclude each other too.
pub struct RegistryLock {
    _file: File,
}

impl RegistryLock {
    pub fn acquire(path: &Path) -> std::io::Result<RegistryLock> {
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)?;
        }
        let name = path.file_name().unwrap_or_default().to_string_lossy();
        let lock_path = path.with_file_name(format!(".{name}.lock"));
        let file = OpenOptions::new()
            .create(true)
            .append(true)
            .read(true)
            .open(lock_path)?;
        // SAFETY: the fd is owned by `file`, which outlives the lock; closing
        // it on drop releases the flock.
        if unsafe { libc::flock(file.as_raw_fd(), libc::LOCK_EX) } != 0 {
            return Err(std::io::Error::last_os_error());
        }
        Ok(RegistryLock { _file: file })
    }
}

#[derive(Clone, Debug, PartialEq)]
pub struct Machine {
    pub key: String,
    pub host: String,
    pub hostname: Option<String>,
}

fn first_label(name: &str) -> String {
    name.split('.').next().unwrap_or("").to_lowercase()
}

impl Machine {
    /// Every spelling that should resolve to this machine on the CLI.
    fn lookup_names(&self) -> [String; 3] {
        [
            self.key.to_lowercase(),
            self.host.to_lowercase(),
            first_label(&self.host),
        ]
    }

    /// Names this machine would call itself. Deliberately excludes `key`: a
    /// short key like "mini" must not match a hostname that looks like it.
    fn local_names(&self) -> Vec<String> {
        let mut names = vec![self.host.to_lowercase(), first_label(&self.host)];
        if let Some(hostname) = &self.hostname {
            names.push(hostname.to_lowercase());
            names.push(first_label(hostname));
        }
        names
    }

    pub fn is_local(&self) -> bool {
        let here = local_hostnames();
        self.local_names().iter().any(|name| here.contains(name))
    }
}

#[derive(Clone, Debug, Default, PartialEq)]
pub struct Project {
    pub key: String,
    pub machine: Option<String>,
    pub path: String,
    pub tmux: Option<bool>,
    pub session: Option<String>,
    pub tmux_path: Option<String>,
    pub description: Option<String>,
}

impl Project {
    pub fn validate(&self) -> Result<(), String> {
        validate_path(&self.path, "project path")?;
        if let Some(tmux_path) = &self.tmux_path {
            validate_path(tmux_path, "project tmux_path")?;
        }
        Ok(())
    }

    /// Where to actually land: `tmux_path` when set, otherwise `path`.
    pub fn workdir(&self) -> &str {
        self.tmux_path.as_deref().unwrap_or(&self.path)
    }

    /// An explicit session is used verbatim; a key-derived one is slugified.
    pub fn session_name(&self) -> String {
        match &self.session {
            Some(session) if !session.is_empty() => session.clone(),
            _ => session_slug(&self.key),
        }
    }

    /// The managed fields, in the order they are written.
    fn to_values(&self) -> Vec<(&'static str, Value)> {
        let mut values = Vec::new();
        if let Some(machine) = &self.machine {
            values.push(("machine", Value::from(machine.as_str())));
        }
        values.push(("path", Value::from(self.path.as_str())));
        if let Some(tmux) = self.tmux {
            values.push(("tmux", Value::from(tmux)));
        }
        // Written only when the session really runs somewhere other than the
        // project directory.
        if let Some(tmux_path) = &self.tmux_path
            && !tmux_path.is_empty()
            && *tmux_path != self.path
        {
            values.push(("tmux_path", Value::from(tmux_path.as_str())));
        }
        if let Some(session) = &self.session
            && !session.is_empty()
        {
            values.push(("tmux_session", Value::from(session.as_str())));
        }
        if let Some(description) = &self.description
            && !description.is_empty()
        {
            values.push(("description", Value::from(description.as_str())));
        }
        values
    }
}

/// How to reach a project: everything workon needs to act.
pub struct Plan {
    pub project: Project,
    pub machine: Option<Machine>,
    pub local: bool,
    /// Where to land -- the project's tmux_path when it has one, else its path.
    pub path: String,
    /// The project directory itself, kept for display.
    pub project_path: String,
    pub session: String,
    pub tmux: bool,
    pub argv: Vec<String>,
}

impl Plan {
    pub fn nested(&self) -> bool {
        self.path != self.project_path
    }
}

/// The shell command that lands you in `path`, in a tmux session or not.
/// Must match tmux_attach_command() in ~/bin/_cmux.py, which cmux uses to open
/// the same projects -- `path` arrives already quoted.
pub fn tmux_attach_command(session: &str, path: &str, tmux: bool) -> String {
    if !tmux {
        return format!("cd {path} && exec bash -l");
    }
    format!(
        "cd {path} && tmux new-session -A -s {} -c {path}",
        quote(session)
    )
}

pub struct Registry {
    pub path: PathBuf,
    pub machines: IndexMap<String, Machine>,
    pub defaults: IndexMap<String, Value>,
    pub projects: IndexMap<String, Project>,
}

fn get_str(table: &Table, key: &str, context: &str) -> Result<Option<String>, String> {
    match table.get(key) {
        None => Ok(None),
        Some(item) => match item.as_str() {
            Some(value) => Ok(Some(value.to_string())),
            None => Err(format!("{context}.{key} must be a string")),
        },
    }
}

fn get_bool(table: &Table, key: &str, context: &str) -> Result<Option<bool>, String> {
    match table.get(key) {
        None => Ok(None),
        Some(item) => match item.as_bool() {
            Some(value) => Ok(Some(value)),
            None => Err(format!("{context}.{key} must be a boolean")),
        },
    }
}

/// A table, whether written as `[a.b]` or as an inline `a.b = { ... }`.
fn as_table(item: &Item) -> Option<Table> {
    match item {
        Item::Table(table) => Some(table.clone()),
        Item::Value(Value::InlineTable(inline)) => Some(inline.clone().into_table()),
        _ => None,
    }
}

impl Registry {
    pub fn empty(path: PathBuf) -> Registry {
        Registry {
            path,
            machines: IndexMap::new(),
            defaults: IndexMap::new(),
            projects: IndexMap::new(),
        }
    }

    /// Read the registry. A missing file is an empty registry, not an error.
    pub fn load(path: PathBuf) -> Result<Registry, String> {
        if !path.is_file() {
            return Ok(Registry::empty(path));
        }
        let text = fs::read_to_string(&path).map_err(|err| err.to_string())?;
        let doc: DocumentMut = text
            .parse()
            .map_err(|err: toml_edit::TomlError| err.to_string().trim_end().to_string())?;

        let mut registry = Registry::empty(path);

        if let Some(item) = doc.get("machines") {
            let table = as_table(item).ok_or("machines must be a table")?;
            for (key, value) in table.iter() {
                let entry = as_table(value).ok_or(format!("machines.{key} must be a table"))?;
                let context = format!("machines.{key}");
                registry.machines.insert(
                    key.to_string(),
                    Machine {
                        key: key.to_string(),
                        host: get_str(&entry, "host", &context)?.unwrap_or(key.to_string()),
                        hostname: get_str(&entry, "hostname", &context)?,
                    },
                );
            }
        }

        if let Some(item) = doc.get("projects") {
            let table = as_table(item).ok_or("projects must be a table")?;
            for (key, value) in table.iter() {
                let entry = as_table(value).ok_or(format!("projects.{key} must be a table"))?;
                let context = format!("projects.{key}");
                // "session" is accepted as a spelling of "tmux_session" so an
                // entry copied out of a cmux session dump drops straight in.
                let session = match get_str(&entry, "tmux_session", &context)? {
                    Some(session) => Some(session),
                    None => get_str(&entry, "session", &context)?,
                };
                let project = Project {
                    key: key.to_string(),
                    machine: get_str(&entry, "machine", &context)?,
                    path: get_str(&entry, "path", &context)?.unwrap_or_default(),
                    tmux: get_bool(&entry, "tmux", &context)?,
                    session,
                    tmux_path: get_str(&entry, "tmux_path", &context)?,
                    description: get_str(&entry, "description", &context)?,
                };
                project.validate()?;
                registry.projects.insert(key.to_string(), project);
            }
        }

        if let Some(item) = doc.get("defaults") {
            let table = as_table(item).ok_or("defaults must be a table")?;
            for (key, value) in table.iter() {
                if let Some(value) = value.as_value() {
                    registry.defaults.insert(key.to_string(), value.clone());
                }
            }
            for field in ["home_dir", "work_dir"] {
                if let Some(value) = registry.defaults.get(field) {
                    let value = value
                        .as_str()
                        .ok_or(format!("defaults.{field} must be a string"))?;
                    validate_path(value, &format!("defaults.{field}"))?;
                }
            }
        }

        let mut unknown: Vec<String> = registry
            .projects
            .values()
            .filter_map(|project| {
                let machine = project.machine.as_ref()?;
                (!registry.machines.contains_key(machine))
                    .then(|| format!("{} -> {machine}", project.key))
            })
            .collect();
        if !unknown.is_empty() {
            unknown.sort();
            return Err(format!(
                "projects reference unknown machines: {}",
                unknown.join(", ")
            ));
        }
        Ok(registry)
    }

    /// Rewrite the file, preserving comments.
    ///
    /// Re-reads the file and edits it in place rather than serializing from
    /// scratch: the file carries the header explaining what each table is
    /// for, and entries can carry comments of their own.
    pub fn save(&self) -> Result<(), String> {
        let is_new = !self.path.is_file();
        let mut doc: DocumentMut = if is_new {
            DocumentMut::new()
        } else {
            let text = fs::read_to_string(&self.path).map_err(|err| err.to_string())?;
            text.parse()
                .map_err(|err: toml_edit::TomlError| err.to_string())?
        };

        let old_machines = doc.get("machines").and_then(as_table);
        let mut machines = Table::new();
        machines.set_implicit(true);
        let mut keys: Vec<&String> = self.machines.keys().collect();
        keys.sort();
        for key in keys {
            let machine = &self.machines[key];
            let mut values = vec![("host", Value::from(machine.host.as_str()))];
            if let Some(hostname) = &machine.hostname {
                values.push(("hostname", Value::from(hostname.as_str())));
            }
            insert_entry(&mut machines, old_machines.as_ref(), key, &values);
        }
        doc.insert("machines", Item::Table(machines));

        if !self.defaults.is_empty() {
            let mut defaults = doc.get("defaults").and_then(as_table).unwrap_or_default();
            let mut keys: Vec<&String> = self.defaults.keys().collect();
            keys.sort();
            let values: Vec<(&str, Value)> = keys
                .into_iter()
                .map(|key| (key.as_str(), self.defaults[key].clone()))
                .collect();
            update_table(&mut defaults, &values);
            doc.insert("defaults", Item::Table(defaults));
        }

        let old_projects = doc.get("projects").and_then(as_table);
        let mut projects = Table::new();
        projects.set_implicit(true);
        let mut keys: Vec<&String> = self.projects.keys().collect();
        keys.sort();
        for key in keys {
            let values = self.projects[key].to_values();
            insert_entry(&mut projects, old_projects.as_ref(), key, &values);
        }
        doc.insert("projects", Item::Table(projects));

        // Tables render in position order, and every table rebuilt above has
        // lost its position. Renumber in document order so each super-table's
        // entries come out sorted, where the key order already put them.
        let mut position = 0;
        renumber(doc.as_table_mut(), &mut position);

        let mut content = doc.to_string();
        if is_new {
            content = format!("{NEW_FILE_HEADER}\n{content}");
        }
        write_atomic(&self.path, &content)
    }

    // -- lookup ----------------------------------------------------------

    /// Resolve a machine by key, ssh name, or short ssh name.
    pub fn machine(&self, name: Option<&str>) -> Option<&Machine> {
        let name = name.filter(|name| !name.is_empty())?;
        if let Some(machine) = self.machines.get(name) {
            return Some(machine);
        }
        let wanted = name.to_lowercase();
        self.machines
            .values()
            .find(|machine| machine.lookup_names().contains(&wanted))
    }

    pub fn project(&self, name: &str) -> Option<&Project> {
        if let Some(project) = self.projects.get(name) {
            return Some(project);
        }
        // Fall back to the slug, so `workon thumb-im` finds a project
        // registered as "thumb.im" -- that is the name tmux shows you.
        let slug = session_slug(name);
        self.projects
            .values()
            .find(|project| session_slug(&project.key) == slug || project.session_name() == name)
    }

    pub fn projects_for_session_slug<'a>(
        &'a self,
        slug: &str,
        projects: Option<&'a IndexMap<String, Project>>,
    ) -> Vec<&'a Project> {
        projects
            .unwrap_or(&self.projects)
            .values()
            .filter(|project| session_slug(&project.session_name()) == slug)
            .collect()
    }

    // -- defaults --------------------------------------------------------

    fn default_str(&self, key: &str, fallback: &str) -> String {
        self.defaults
            .get(key)
            .and_then(|value| value.as_str())
            .unwrap_or(fallback)
            .to_string()
    }

    pub fn home_dir(&self) -> String {
        self.default_str("home_dir", "~/Projects")
    }

    pub fn work_dir(&self) -> String {
        self.default_str("work_dir", "~/Work")
    }

    /// Whether a project with no `tmux` of its own gets a session. Off: a
    /// project gets a session because it says so.
    pub fn tmux_default(&self) -> bool {
        self.defaults
            .get("tmux")
            .and_then(|value| value.as_bool())
            .unwrap_or(false)
    }

    pub fn default_dir(&self, work: bool) -> String {
        if work {
            self.work_dir()
        } else {
            self.home_dir()
        }
    }

    // -- planning --------------------------------------------------------

    /// Work out how to reach `project` and build the command that does it.
    pub fn plan(&self, project: &Project) -> Result<Plan, String> {
        let machine = self.machine(project.machine.as_deref()).cloned();
        if let Some(name) = &project.machine
            && machine.is_none()
        {
            return Err(format!(
                "project {} references unknown machine {}",
                py_repr(&project.key),
                py_repr(name)
            ));
        }
        let local = machine.as_ref().is_none_or(Machine::is_local);
        let tmux = project.tmux.unwrap_or_else(|| self.tmux_default());
        let session = project.session_name();
        let workdir = project.workdir().to_string();

        let argv = match (&machine, local) {
            (Some(machine), false) => remote_argv(machine, &workdir, &session, tmux),
            _ => Vec::new(),
        };
        Ok(Plan {
            project: project.clone(),
            machine,
            local,
            path: workdir,
            project_path: project.path.clone(),
            session,
            tmux,
            argv,
        })
    }
}

fn remote_argv(machine: &Machine, path: &str, session: &str, tmux: bool) -> Vec<String> {
    let path_expr = if path.is_empty() {
        "\"$HOME\"".to_string()
    } else {
        remote_path_expr(path)
    };
    let command = tmux_attach_command(session, &path_expr, tmux);

    // bash -lc on both paths: the login profile is what puts Homebrew's tmux
    // on PATH, and mosh-server execs the command directly.
    if which("mosh").is_some() {
        // "--" stops mosh parsing the command's own flags as its options.
        return ["mosh", &machine.host, "--", "bash", "-lc", &command]
            .map(String::from)
            .to_vec();
    }
    // ssh re-parses on the remote, so the command is quoted as one word.
    vec![
        "ssh".into(),
        "-t".into(),
        machine.host.clone(),
        format!("bash -lc {}", quote(&command)),
    ]
}

/// Put `key` into `table`, reusing the entry already in the file (and so its
/// comments and key spelling) when there is one.
fn insert_entry(table: &mut Table, old: Option<&Table>, key: &str, values: &[(&str, Value)]) {
    let old_entry = old.and_then(|old| old.get(key)).and_then(as_table);
    let mut entry = old_entry.unwrap_or_default();
    update_table(&mut entry, values);
    let formatted = old
        .and_then(|old| old.key(key))
        .cloned()
        .unwrap_or_else(|| Key::new(key));
    table.insert_formatted(&formatted, Item::Table(entry));
}

/// Update managed values while retaining comments on surviving keys. Every key
/// not in `values` is dropped, as the Python side does.
fn update_table(table: &mut Table, values: &[(&str, Value)]) {
    table.retain(|key, _| values.iter().any(|(wanted, _)| *wanted == key));
    for (key, value) in values {
        let mut value = value.clone();
        if let Some(old) = table.get(key).and_then(Item::as_value) {
            *value.decor_mut() = old.decor().clone();
        }
        table.insert(key, Item::Value(value));
    }
}

fn renumber(table: &mut Table, position: &mut usize) {
    for (_, item) in table.iter_mut() {
        match item {
            Item::Table(child) => {
                child.set_position(*position);
                *position += 1;
                renumber(child, position);
            }
            Item::ArrayOfTables(array) => {
                for child in array.iter_mut() {
                    child.set_position(*position);
                    *position += 1;
                    renumber(child, position);
                }
            }
            _ => {}
        }
    }
}

/// Replace a file's contents in one step: a unique temp file beside the
/// destination, fsynced, then renamed over it.
pub fn write_atomic(path: &Path, content: &str) -> Result<(), String> {
    let parent = path.parent().unwrap_or(Path::new("."));
    fs::create_dir_all(parent).map_err(|err| err.to_string())?;
    let mode = fs::metadata(path)
        .map(|meta| meta.permissions().mode() & 0o777)
        .unwrap_or(0o600);
    let name = path.file_name().unwrap_or_default().to_string_lossy();
    let mut tmp = tempfile::Builder::new()
        .prefix(&format!(".{name}."))
        .suffix(".tmp")
        .tempfile_in(parent)
        .map_err(|err| err.to_string())?;
    tmp.as_file()
        .set_permissions(fs::Permissions::from_mode(mode))
        .map_err(|err| err.to_string())?;
    tmp.write_all(content.as_bytes())
        .map_err(|err| err.to_string())?;
    tmp.as_file().sync_all().map_err(|err| err.to_string())?;
    tmp.persist(path).map_err(|err| err.to_string())?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample() -> Registry {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.keep().join("projects.toml");
        fs::write(
            &path,
            r#"# header comment

[defaults]
home_dir = "~/Projects"
work_dir = "~/Work"

[machines.mini]
host = "mac-mini-pro-2023"

[projects."thumb.im"]
path = "~/Projects/thumb.im" # keep me

[projects.alpha]
machine = "mini"
path = "~/Projects/alpha"
tmux = true
"#,
        )
        .unwrap();
        Registry::load(path).unwrap()
    }

    #[test]
    fn project_lookup_falls_back_to_slug() {
        let registry = sample();
        assert_eq!(registry.project("thumb-im").unwrap().key, "thumb.im");
        assert!(registry.project("nope").is_none());
    }

    #[test]
    fn machine_lookup_by_host() {
        let registry = sample();
        assert_eq!(
            registry.machine(Some("MAC-MINI-PRO-2023")).unwrap().key,
            "mini"
        );
        assert!(registry.machine(Some("")).is_none());
    }

    #[test]
    fn tmux_attach_matches_python() {
        assert_eq!(
            tmux_attach_command("a b", "\"$HOME\"/x", true),
            "cd \"$HOME\"/x && tmux new-session -A -s 'a b' -c \"$HOME\"/x"
        );
        assert_eq!(
            tmux_attach_command("s", "/x", false),
            "cd /x && exec bash -l"
        );
    }

    #[test]
    fn save_round_trips_and_sorts() {
        let mut registry = sample();
        registry.projects.insert(
            "aaa".into(),
            Project {
                key: "aaa".into(),
                path: "~/Projects/aaa".into(),
                ..Default::default()
            },
        );
        registry.save().unwrap();
        let text = fs::read_to_string(&registry.path).unwrap();
        let aaa = text.find("[projects.aaa]").unwrap();
        let alpha = text.find("[projects.alpha]").unwrap();
        let thumb = text.find("[projects.\"thumb.im\"]").unwrap();
        assert!(aaa < alpha && alpha < thumb, "{text}");
        assert!(text.starts_with("# header comment"));
        assert!(text.contains("# keep me"));
        // Loads back to the same thing.
        let again = Registry::load(registry.path.clone()).unwrap();
        assert_eq!(again.projects.len(), 3);
    }

    #[test]
    fn unknown_machine_is_an_error() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("p.toml");
        fs::write(&path, "[projects.x]\nmachine = \"gone\"\npath = \"~/x\"\n").unwrap();
        let err = Registry::load(path).err().unwrap();
        assert!(err.contains("x -> gone"), "{err}");
    }
}
