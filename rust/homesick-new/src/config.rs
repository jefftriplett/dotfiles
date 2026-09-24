//! Where the dotfiles repo lives, and how it maps onto $HOME.
//!
//! homesick hard-coded ~/.homesick/repos/<castle>/home. Here the repo can live
//! anywhere, found in this order -- first one set wins:
//!
//!   1. --dir PATH
//!   2. $HOMESICK_DIR
//!   3. $HOMESICK_REPO (what the dotfiles justfile already exports)
//!   4. `dir` in the config file
//!   5. ~/.homesick/repos/dotfiles, so an existing checkout just works
//!
//! The config file is $HOMESICK_CONFIG, else $XDG_CONFIG_HOME/homesick/
//! config.toml (~/.config/homesick/config.toml). Every key is optional:
//!
//!   dir = "~/src/dotfiles"      # the repo
//!   home_subdir = "home"        # the folder inside it mirrored into $HOME;
//!                               # "." for a repo whose root is the mirror
//!   target = "~"                # where the links go
//!   ignore = [".DS_Store"]      # names never linked, at any depth

use std::env;
use std::fs;
use std::path::{Path, PathBuf};

use toml_edit::DocumentMut;

pub const SUBDIR_FILENAME: &str = ".homesick_subdir";
const DEFAULT_IGNORE: [&str; 2] = [".DS_Store", ".git"];

pub struct Config {
    /// The dotfiles repo root: git runs here, .homesick_subdir lives here.
    pub dir: PathBuf,
    /// Where `dir` came from, for `homesick-new config`.
    pub dir_source: String,
    /// The folder mirrored into `target` (`dir`/home by default).
    pub home: PathBuf,
    /// Where links are created, normally $HOME.
    pub target: PathBuf,
    pub ignore: Vec<String>,
    pub config_file: PathBuf,
    pub config_file_exists: bool,
}

pub fn home() -> PathBuf {
    env::var_os("HOME")
        .filter(|h| !h.is_empty())
        .map(PathBuf::from)
        .unwrap_or_else(|| PathBuf::from("/"))
}

pub fn expand(path: &str) -> PathBuf {
    if path == "~" {
        return home();
    }
    if let Some(rest) = path.strip_prefix("~/") {
        return home().join(rest);
    }
    PathBuf::from(path)
}

fn non_empty_env(name: &str) -> Option<String> {
    env::var(name).ok().filter(|v| !v.trim().is_empty())
}

pub fn config_file() -> PathBuf {
    if let Some(path) = non_empty_env("HOMESICK_CONFIG") {
        return expand(&path);
    }
    let base = non_empty_env("XDG_CONFIG_HOME")
        .map(PathBuf::from)
        .unwrap_or_else(|| home().join(".config"));
    base.join("homesick").join("config.toml")
}

#[derive(Default)]
struct FileSettings {
    dir: Option<String>,
    home_subdir: Option<String>,
    target: Option<String>,
    ignore: Option<Vec<String>>,
}

fn read_settings(path: &Path) -> Result<FileSettings, String> {
    let text = fs::read_to_string(path).map_err(|e| format!("{}: {e}", path.display()))?;
    let doc: DocumentMut = text
        .parse()
        .map_err(|e: toml_edit::TomlError| format!("{}: {e}", path.display()))?;
    let string = |key: &str| -> Result<Option<String>, String> {
        match doc.get(key) {
            None => Ok(None),
            Some(item) => item
                .as_str()
                .map(|s| Some(s.to_string()))
                .ok_or(format!("{}: `{key}` must be a string", path.display())),
        }
    };
    let ignore = match doc.get("ignore") {
        None => None,
        Some(item) => {
            let array = item
                .as_array()
                .ok_or(format!("{}: `ignore` must be a list", path.display()))?;
            Some(
                array
                    .iter()
                    .map(|v| v.as_str().map(String::from))
                    .collect::<Option<Vec<_>>>()
                    .ok_or(format!("{}: `ignore` must hold strings", path.display()))?,
            )
        }
    };
    Ok(FileSettings {
        dir: string("dir")?,
        home_subdir: string("home_subdir")?,
        target: string("target")?,
        ignore,
    })
}

/// Physical path, like Ruby's Pathname#realpath; falls back to the path as
/// given when it does not exist (yet).
fn real(path: PathBuf) -> PathBuf {
    fs::canonicalize(&path).unwrap_or(path)
}

pub fn resolve(dir_flag: Option<&str>, target_flag: Option<&str>) -> Result<Config, String> {
    let config_file = config_file();
    let config_file_exists = config_file.is_file();
    let settings = if config_file_exists {
        read_settings(&config_file)?
    } else {
        FileSettings::default()
    };

    let (dir, dir_source) = if let Some(dir) = dir_flag {
        (dir.to_string(), "--dir".to_string())
    } else if let Some(dir) = non_empty_env("HOMESICK_DIR") {
        (dir, "$HOMESICK_DIR".to_string())
    } else if let Some(dir) = non_empty_env("HOMESICK_REPO") {
        (dir, "$HOMESICK_REPO".to_string())
    } else if let Some(dir) = settings.dir.clone() {
        (dir, config_file.display().to_string())
    } else {
        (
            "~/.homesick/repos/dotfiles".to_string(),
            "default".to_string(),
        )
    };
    let dir = real(expand(&dir));

    let home_subdir = settings.home_subdir.unwrap_or_else(|| "home".to_string());
    let home = if home_subdir.is_empty() || home_subdir == "." {
        dir.clone()
    } else {
        dir.join(&home_subdir)
    };

    let target = target_flag
        .map(String::from)
        .or(settings.target)
        .map(|t| expand(&t))
        .unwrap_or_else(self::home);

    let mut ignore = settings
        .ignore
        .unwrap_or_else(|| DEFAULT_IGNORE.map(String::from).to_vec());
    // A repo whose root is the mirror must never link its own metadata.
    if home == dir {
        for name in [".git", SUBDIR_FILENAME] {
            if !ignore.iter().any(|i| i == name) {
                ignore.push(name.to_string());
            }
        }
    }

    Ok(Config {
        dir,
        dir_source,
        home: real(home),
        target: real(target),
        ignore,
        config_file,
        config_file_exists,
    })
}

impl Config {
    pub fn subdir_file(&self) -> PathBuf {
        self.dir.join(SUBDIR_FILENAME)
    }

    /// Lines of .homesick_subdir: folders whose *contents* are linked one by
    /// one instead of the folder itself. Blank lines and `#` comments are
    /// skipped, and a trailing slash is tolerated.
    pub fn subdirs(&self) -> Vec<String> {
        let Ok(text) = fs::read_to_string(self.subdir_file()) else {
            return Vec::new();
        };
        text.lines()
            .map(|line| line.trim().trim_end_matches('/').to_string())
            .filter(|line| !line.is_empty() && !line.starts_with('#'))
            .collect()
    }

    pub fn require_home(&self) -> Result<(), String> {
        if self.home.is_dir() {
            return Ok(());
        }
        Err(format!(
            "expected {} to exist and contain dotfiles (repo from {})",
            self.home.display(),
            self.dir_source
        ))
    }
}
