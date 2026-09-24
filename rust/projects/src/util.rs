//! Small shared helpers: quoting, paths, hostnames, subprocesses, colour.
//!
//! Each of these mirrors a helper the Python side keeps in _cmux.py or
//! _projects.py, and has to agree with it byte for byte where the output is
//! consumed by something else -- a session slug, a quoted argv, an eval'd line.

use std::env;
use std::ffi::CStr;
use std::io::{IsTerminal, Read};
use std::path::{Path, PathBuf};
use std::process::{Command, ExitStatus, Stdio};
use std::thread;
use std::time::{Duration, Instant};

// -- quoting -------------------------------------------------------------

/// Python's shlex.quote: bare when every byte is "safe", else single-quoted.
pub fn quote(value: &str) -> String {
    if value.is_empty() {
        return "''".to_string();
    }
    let safe = value
        .bytes()
        .all(|b| b.is_ascii_alphanumeric() || b"_@%+=:,./-".contains(&b));
    if safe {
        return value.to_string();
    }
    format!("'{}'", value.replace('\'', "'\"'\"'"))
}

/// Python's shlex.join.
pub fn join<S: AsRef<str>>(argv: &[S]) -> String {
    argv.iter()
        .map(|arg| quote(arg.as_ref()))
        .collect::<Vec<_>>()
        .join(" ")
}

/// Python's shlex.split, for the handful of places that take a command line
/// from the environment ($EDITOR). Handles quotes and backslashes, which is
/// everything an editor setting realistically contains.
pub fn split(line: &str) -> Vec<String> {
    let mut words = Vec::new();
    let mut current = String::new();
    let mut in_word = false;
    let mut chars = line.chars();
    while let Some(c) = chars.next() {
        match c {
            '\'' => {
                in_word = true;
                for c in chars.by_ref() {
                    if c == '\'' {
                        break;
                    }
                    current.push(c);
                }
            }
            '"' => {
                in_word = true;
                while let Some(c) = chars.next() {
                    match c {
                        '"' => break,
                        '\\' => {
                            if let Some(next) = chars.next() {
                                current.push(next);
                            }
                        }
                        _ => current.push(c),
                    }
                }
            }
            '\\' => {
                in_word = true;
                if let Some(next) = chars.next() {
                    current.push(next);
                }
            }
            c if c.is_whitespace() => {
                if in_word {
                    words.push(std::mem::take(&mut current));
                    in_word = false;
                }
            }
            c => {
                in_word = true;
                current.push(c);
            }
        }
    }
    if in_word {
        words.push(current);
    }
    words
}

/// tmux session names may not contain ":" or "."; spaces are legal but a
/// nuisance to type at `tmux attach -t`. Must agree with session_slug() in
/// ~/bin/_cmux.py and tmux_session_slug in ~/.tmux_session_name.bash.
pub fn session_slug(name: &str) -> String {
    name.replace([':', '.', ' '], "-")
}

// -- paths ---------------------------------------------------------------

pub fn home() -> PathBuf {
    env::var_os("HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/"))
}

/// Path::expanduser for the "~" and "~/..." forms the registry stores.
pub fn expand(path: &str) -> PathBuf {
    if path == "~" {
        return home();
    }
    if let Some(rest) = path.strip_prefix("~/") {
        return home().join(rest);
    }
    PathBuf::from(path)
}

pub fn expand_str(path: &str) -> String {
    expand(path).to_string_lossy().into_owned()
}

/// Rewrite this machine's home prefix back to "~", so a stored path means the
/// right thing on whichever Mac reads it.
pub fn tildify(path: &str) -> String {
    let home = home();
    let home = home.to_string_lossy();
    if path == home {
        return "~".to_string();
    }
    match path.strip_prefix(&format!("{home}/")) {
        Some(rest) => format!("~/{rest}"),
        None => path.to_string(),
    }
}

/// Require portable registry paths, not cwd-relative surprises.
pub fn validate_path(value: &str, field: &str) -> Result<String, String> {
    if value.trim().is_empty() {
        return Err(format!("{field} must not be empty"));
    }
    if value.starts_with("~/") || Path::new(value).is_absolute() {
        return Ok(value.to_string());
    }
    Err(format!(
        "{field} must be absolute or start with '~/' (got {})",
        py_repr(value)
    ))
}

/// Python's repr() of a str, close enough for error messages.
pub fn py_repr(value: &str) -> String {
    if value.contains('\'') && !value.contains('"') {
        format!("\"{value}\"")
    } else {
        format!("'{}'", value.replace('\\', "\\\\").replace('\'', "\\'"))
    }
}

/// Shell expression for `path` as evaluated on the *remote* host: a leading
/// "~" has to survive quoting and expand over there, not here.
pub fn remote_path_expr(path: &str) -> String {
    if path == "~" {
        return "\"$HOME\"".to_string();
    }
    if let Some(rest) = path.strip_prefix("~/") {
        return format!("\"$HOME\"/{}", quote(rest));
    }
    quote(path)
}

pub fn which(binary: &str) -> Option<PathBuf> {
    let path = env::var_os("PATH")?;
    env::split_paths(&path)
        .map(|dir| dir.join(binary))
        .find(|candidate| is_executable(candidate))
}

fn is_executable(path: &Path) -> bool {
    use std::os::unix::fs::PermissionsExt;
    path.metadata()
        .map(|meta| meta.is_file() && meta.permissions().mode() & 0o111 != 0)
        .unwrap_or(false)
}

pub fn config_home() -> PathBuf {
    match env::var_os("XDG_CONFIG_HOME") {
        Some(dir) if !dir.is_empty() => PathBuf::from(dir),
        _ => home().join(".config"),
    }
}

/// ~/.config/cmux-tmux, shared with the cmux-* scripts.
pub fn cmux_config_dir() -> PathBuf {
    config_home().join("cmux-tmux")
}

// -- hostnames -----------------------------------------------------------

pub fn hostname() -> String {
    let mut buf = [0 as libc::c_char; 256];
    // SAFETY: buf is writable for its full length and gethostname NUL-terminates
    // on success; the last byte is forced to NUL in case it truncated.
    unsafe {
        if libc::gethostname(buf.as_mut_ptr(), buf.len()) != 0 {
            return String::new();
        }
        buf[buf.len() - 1] = 0;
        CStr::from_ptr(buf.as_ptr()).to_string_lossy().into_owned()
    }
}

/// The names this machine calls itself: the full hostname and its first
/// dotted component, lowercased.
pub fn local_hostnames() -> Vec<String> {
    let name = hostname().to_lowercase();
    let short = name.split('.').next().unwrap_or("").to_string();
    let mut names = vec![name];
    if !names.contains(&short) {
        names.push(short);
    }
    names
}

// -- subprocesses --------------------------------------------------------

pub struct Output {
    pub status: ExitStatus,
    pub stdout: String,
    pub stderr: String,
}

pub enum RunError {
    Io(std::io::Error),
    Timeout,
}

impl std::fmt::Display for RunError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            RunError::Io(err) => write!(f, "{err}"),
            RunError::Timeout => write!(f, "timed out"),
        }
    }
}

/// subprocess.run(capture_output=True, text=True, timeout=...).
///
/// The pipes are drained on their own threads so a chatty child cannot fill a
/// pipe and deadlock against the wait below.
pub fn run_captured(argv: &[String], timeout: Option<Duration>) -> Result<Output, RunError> {
    let mut child = Command::new(&argv[0])
        .args(&argv[1..])
        .stdin(Stdio::null())
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .map_err(RunError::Io)?;

    let mut stdout = child.stdout.take().expect("piped stdout");
    let mut stderr = child.stderr.take().expect("piped stderr");
    let out_reader = thread::spawn(move || {
        let mut buf = Vec::new();
        let _ = stdout.read_to_end(&mut buf);
        buf
    });
    let err_reader = thread::spawn(move || {
        let mut buf = Vec::new();
        let _ = stderr.read_to_end(&mut buf);
        buf
    });

    let started = Instant::now();
    let status = loop {
        match child.try_wait().map_err(RunError::Io)? {
            Some(status) => break status,
            None => {
                if let Some(limit) = timeout
                    && started.elapsed() >= limit
                {
                    let _ = child.kill();
                    let _ = child.wait();
                    return Err(RunError::Timeout);
                }
                thread::sleep(Duration::from_millis(10));
            }
        }
    };

    let stdout = out_reader.join().unwrap_or_default();
    let stderr = err_reader.join().unwrap_or_default();
    Ok(Output {
        status,
        stdout: String::from_utf8_lossy(&stdout).into_owned(),
        stderr: String::from_utf8_lossy(&stderr).into_owned(),
    })
}

// -- colour --------------------------------------------------------------

/// Styles are named for what they mean, not what colour they are -- the same
/// theme the Python `projects` used through rich.
#[derive(Clone, Copy)]
pub enum Style {
    Add,
    Update,
    Would,
    ReasonSession,
    ReasonSessionIdle,
    ReasonWorkspace,
    ReasonDefault,
    Machine,
    Path,
    Extra,
    Name,
    Warn,
    Error,
    Muted,
}

impl Style {
    fn code(self) -> &'static str {
        match self {
            Style::Add => "1;32",
            Style::Update => "1;33",
            Style::Would => "1;36",
            Style::ReasonSession => "32",
            Style::ReasonSessionIdle => "38;5;65",
            Style::ReasonWorkspace => "36",
            Style::ReasonDefault => "2",
            Style::Machine => "35",
            Style::Path => "34",
            Style::Extra => "2;36",
            Style::Name => "1",
            Style::Warn => "33",
            Style::Error => "1;31",
            Style::Muted => "2",
        }
    }

    pub fn for_reason(reason: &str) -> Style {
        match reason {
            "session" => Style::ReasonSession,
            "session-idle" => Style::ReasonSessionIdle,
            "workspace" => Style::ReasonWorkspace,
            _ => Style::ReasonDefault,
        }
    }
}

fn colour_enabled(is_tty: bool) -> bool {
    if env::var_os("NO_COLOR").is_some_and(|v| !v.is_empty()) {
        return false;
    }
    if env::var_os("FORCE_COLOR").is_some_and(|v| !v.is_empty()) {
        return true;
    }
    is_tty && env::var("TERM").map(|t| t != "dumb").unwrap_or(true)
}

pub fn stdout_colour() -> bool {
    colour_enabled(std::io::stdout().is_terminal())
}

pub fn stderr_colour() -> bool {
    colour_enabled(std::io::stderr().is_terminal())
}

/// Styled text for stdout.
pub fn paint(style: Style, text: &str) -> String {
    paint_if(stdout_colour(), style, text)
}

pub fn paint_if(enabled: bool, style: Style, text: &str) -> String {
    if enabled && !text.is_empty() {
        format!("\x1b[{}m{text}\x1b[0m", style.code())
    } else {
        text.to_string()
    }
}

pub fn warn(message: &str) {
    eprintln!("{}", paint_if(stderr_colour(), Style::Warn, message));
}

pub fn fail(message: &str) {
    eprintln!("{}", paint_if(stderr_colour(), Style::Error, message));
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn quote_matches_shlex() {
        assert_eq!(quote(""), "''");
        assert_eq!(quote("plain-name_1.2"), "plain-name_1.2");
        assert_eq!(quote("~/Projects"), "'~/Projects'");
        assert_eq!(quote("has space"), "'has space'");
        assert_eq!(quote("it's"), "'it'\"'\"'s'");
        assert_eq!(quote("a=b:c,d@e%f+g"), "a=b:c,d@e%f+g");
    }

    #[test]
    fn split_handles_quotes() {
        assert_eq!(split("code --wait"), vec!["code", "--wait"]);
        assert_eq!(split("'my editor' -w"), vec!["my editor", "-w"]);
        assert_eq!(split(r#""a b"\ c"#), vec!["a b c"]);
    }

    #[test]
    fn slug_replaces_separators() {
        assert_eq!(session_slug("thumb.im"), "thumb-im");
        assert_eq!(session_slug("a:b c.d"), "a-b-c-d");
    }

    #[test]
    fn remote_path_expands_over_there() {
        assert_eq!(remote_path_expr("~"), "\"$HOME\"");
        assert_eq!(
            remote_path_expr("~/Projects/x y"),
            "\"$HOME\"/'Projects/x y'"
        );
        assert_eq!(remote_path_expr("/opt/app"), "/opt/app");
    }

    #[test]
    fn validate_rejects_relative() {
        assert!(validate_path("~/x", "p").is_ok());
        assert!(validate_path("/x", "p").is_ok());
        assert!(validate_path("x", "p").is_err());
        assert!(validate_path("  ", "p").is_err());
    }
}
