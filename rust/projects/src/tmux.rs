//! tmux sessions (here and over ssh) and the cmux session dump.
//!
//! The pieces of ~/bin/_cmux.py that `projects` uses: listing and killing
//! sessions, and reading the machine each cmux workspace is pinned to.

use std::fs;
use std::path::PathBuf;
use std::time::Duration;

use toml_edit::{DocumentMut, Item, Table, Value};

use crate::util::{RunError, cmux_config_dir, join, quote, run_captured, session_slug};

/// Fields joined with US (\x1f): no tmux name or path contains a control char,
/// so it is an unambiguous delimiter where a tab would not be.
const SESSION_DELIM: char = '\x1f';
const SESSION_FORMAT: &str =
    "#{session_name}\x1f#{session_attached}\x1f#{session_path}\x1f#{session_windows}";

#[derive(Clone, Debug)]
pub struct TmuxSession {
    pub name: String,
    pub attached: i64,
    pub path: String,
    pub windows: i64,
}

impl TmuxSession {
    pub fn is_attached(&self) -> bool {
        self.attached > 0
    }
}

/// Lines that do not split into the expected fields are skipped: a remote
/// `bash -lc` may interleave login-profile chatter with the real output.
pub fn parse_sessions(stdout: &str) -> Vec<TmuxSession> {
    stdout
        .lines()
        .filter(|line| !line.trim().is_empty())
        .filter_map(|line| {
            let parts: Vec<&str> = line.split(SESSION_DELIM).collect();
            let [name, attached, path, windows] = parts.as_slice() else {
                return None;
            };
            Some(TmuxSession {
                name: name.to_string(),
                attached: attached.trim().parse().ok()?,
                path: path.to_string(),
                windows: windows.trim().parse().ok()?,
            })
        })
        .collect()
}

pub enum ProbeError {
    Timeout(u64),
    Failed(String),
}

impl std::fmt::Display for ProbeError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ProbeError::Timeout(seconds) => write!(f, "timed out after {seconds}s"),
            ProbeError::Failed(message) => write!(f, "{message}"),
        }
    }
}

fn ssh_argv(host: &str, timeout: u64, command: &str) -> Vec<String> {
    vec![
        "ssh".into(),
        "-o".into(),
        "BatchMode=yes".into(),
        "-o".into(),
        format!("ConnectTimeout={timeout}"),
        host.into(),
        format!("bash -lc {}", quote(command)),
    ]
}

/// Sessions here, or on `host` over ssh. Empty when no server runs.
///
/// ssh rather than mosh: this is a one-shot non-interactive command.
/// BatchMode means a host that would prompt fails fast instead of hanging, and
/// the overall timeout guards an ssh that connects but never returns.
pub fn sessions(host: Option<&str>, timeout: u64) -> Result<Vec<TmuxSession>, ProbeError> {
    let tmux = ["tmux", "list-sessions", "-F", SESSION_FORMAT].map(String::from);
    let (argv, limit) = match host {
        None => (tmux.to_vec(), None),
        Some(host) => (
            ssh_argv(host, timeout, &join(&tmux)),
            Some(Duration::from_secs(timeout * 4)),
        ),
    };
    let output = run_captured(&argv, limit).map_err(|err| match err {
        RunError::Timeout => ProbeError::Timeout(timeout * 4),
        RunError::Io(err) => ProbeError::Failed(err.to_string()),
    })?;
    if !output.status.success() {
        // "no server running on ..." is the normal no-sessions case.
        if output.stderr.contains("no server running") {
            return Ok(Vec::new());
        }
        let message = output.stderr.trim();
        return Err(ProbeError::Failed(match (host, message.is_empty()) {
            (_, false) if host.is_none() => format!("tmux list-sessions failed: {message}"),
            (_, false) => message.to_string(),
            _ => format!("ssh exited {}", output.status.code().unwrap_or(-1)),
        }));
    }
    Ok(parse_sessions(&output.stdout))
}

/// Kill one session, here or on `host`. "-t=name" rather than "-t name":
/// a bare -t matches as a prefix, and would happily kill "agents-scratch" if
/// "agents" itself had already gone away.
pub fn kill_session(name: &str, host: Option<&str>, timeout: u64) -> Result<(), String> {
    let tmux = vec![
        "tmux".to_string(),
        "kill-session".into(),
        format!("-t={name}"),
    ];
    let (argv, limit) = match host {
        None => (tmux, None),
        Some(host) => (
            ssh_argv(host, timeout, &join(&tmux)),
            Some(Duration::from_secs(timeout * 4)),
        ),
    };
    let output = run_captured(&argv, limit).map_err(|err| err.to_string())?;
    if !output.status.success() {
        let message = output.stderr.trim();
        return Err(if message.is_empty() {
            format!("exited {}", output.status.code().unwrap_or(-1))
        } else {
            message.to_string()
        });
    }
    Ok(())
}

// -- cmux session dump ---------------------------------------------------

const MOSH_PREFIX: &str = "[mosh] ";

/// One workspace from ~/.config/cmux-tmux/session-dump.{toml,json}, reduced to
/// the fields the import reads.
pub struct Workspace {
    pub title: String,
    pub cwd: String,
    pub host: Option<String>,
    pub session: Option<String>,
}

impl Workspace {
    /// The title without the display-only "[mosh] " label.
    pub fn base_title(&self) -> &str {
        let mut title = self.title.as_str();
        while let Some(rest) = title.strip_prefix(MOSH_PREFIX) {
            title = rest;
        }
        title
    }

    pub fn session_name(&self) -> String {
        match &self.session {
            Some(session) if !session.is_empty() => session.clone(),
            _ => session_slug(self.base_title()),
        }
    }
}

/// Prefer the TOML dump; fall back to JSON only if the TOML is absent.
pub fn default_dump_path() -> PathBuf {
    let toml = cmux_config_dir().join("session-dump.toml");
    if toml.is_file() {
        toml
    } else {
        cmux_config_dir().join("session-dump.json")
    }
}

fn toml_str(table: &Table, key: &str) -> Option<String> {
    table.get(key).and_then(Item::as_str).map(String::from)
}

/// Read a dump: a bare list of workspaces or a {"workspaces": [...]} wrapper,
/// in either format. Entries without a title or cwd are an error, as they are
/// for the Python loader.
pub fn load_dump(path: &PathBuf) -> Result<Vec<Workspace>, String> {
    let text = fs::read_to_string(path).map_err(|err| err.to_string())?;
    let is_json = path.extension().is_some_and(|ext| ext == "json");
    let mut found = Vec::new();

    if is_json {
        let data: serde_json::Value = serde_json::from_str(&text).map_err(|err| err.to_string())?;
        let list = match &data {
            serde_json::Value::Object(map) => map.get("workspaces").cloned(),
            other => Some(other.clone()),
        };
        let Some(serde_json::Value::Array(list)) = list else {
            return Err("dump has no workspaces list".into());
        };
        for entry in list {
            let get = |key: &str| entry.get(key).and_then(|v| v.as_str()).map(String::from);
            found.push(Workspace {
                title: get("title").ok_or("workspace without a title")?,
                cwd: get("cwd").ok_or("workspace without a cwd")?,
                // "machine" is the pre-rename spelling of "host".
                host: get("host").or_else(|| get("machine")),
                session: get("session"),
            });
        }
        return Ok(found);
    }

    let doc: DocumentMut = text
        .parse()
        .map_err(|err: toml_edit::TomlError| err.to_string())?;
    let tables: Vec<Table> = match doc.get("workspaces") {
        Some(Item::ArrayOfTables(array)) => array.iter().cloned().collect(),
        Some(Item::Value(Value::Array(array))) => array
            .iter()
            .filter_map(|value| value.as_inline_table().map(|t| t.clone().into_table()))
            .collect(),
        _ => return Err("dump has no workspaces list".into()),
    };
    for table in tables {
        found.push(Workspace {
            title: toml_str(&table, "title").ok_or("workspace without a title")?,
            cwd: toml_str(&table, "cwd").ok_or("workspace without a cwd")?,
            host: toml_str(&table, "host").or_else(|| toml_str(&table, "machine")),
            session: toml_str(&table, "session"),
        });
    }
    Ok(found)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn parses_and_skips_noise() {
        let out = "Last login: whenever\nmain\x1f1\x1f/Users/x/p\x1f3\nbad\x1fx\x1f/p\x1f1\n";
        let sessions = parse_sessions(out);
        assert_eq!(sessions.len(), 1);
        assert_eq!(sessions[0].name, "main");
        assert!(sessions[0].is_attached());
        assert_eq!(sessions[0].windows, 3);
    }

    #[test]
    fn base_title_strips_every_mosh_prefix() {
        let ws = Workspace {
            title: "[mosh] [mosh] thumb.im".into(),
            cwd: "~".into(),
            host: None,
            session: None,
        };
        assert_eq!(ws.base_title(), "thumb.im");
        assert_eq!(ws.session_name(), "thumb-im");
    }
}
