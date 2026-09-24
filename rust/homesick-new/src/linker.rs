//! The symlink engine: homesick's `link` and `unlink`, minus castles.
//!
//! Every top-level entry of the mirror folder becomes one symlink in the
//! target -- a folder is linked whole, not recursed into. The exception is a
//! folder named in .homesick_subdir (and each of its ancestors): that one is
//! left alone, and its children are linked individually instead. That is how
//! ~/.config stays a real directory while ~/.config/direnv is a link.

use std::collections::HashSet;
use std::fs;
use std::io::{self, BufRead, IsTerminal, Write};
use std::path::{Path, PathBuf};
use std::process::Command;

use crate::config::Config;
use crate::ui::{Color, Ui};

/// One link homesick would manage: `source` in the repo, `dest` in $HOME.
pub struct Entry {
    pub source: PathBuf,
    pub dest: PathBuf,
}

/// Every link, in a stable order: the mirror's own entries first, then each
/// .homesick_subdir folder's children, in the order the file lists them.
pub fn plan(config: &Config, ui: &Ui) -> Vec<Entry> {
    let subdirs = config.subdirs();

    // A subdir and all of its ancestors are never linked themselves.
    let mut skip: HashSet<PathBuf> = HashSet::new();
    for subdir in &subdirs {
        let mut path = PathBuf::from(subdir);
        loop {
            skip.insert(path.clone());
            if !path.pop() || path.as_os_str().is_empty() {
                break;
            }
        }
    }

    let mut bases = vec![PathBuf::new()];
    bases.extend(subdirs.iter().map(PathBuf::from));

    let mut entries = Vec::new();
    for base in bases {
        let dir = config.home.join(&base);
        let Ok(read) = fs::read_dir(&dir) else {
            if !base.as_os_str().is_empty() {
                ui.status(
                    "missing",
                    Color::Yellow,
                    &format!(
                        "{} is listed in .homesick_subdir but not in the repo",
                        base.display()
                    ),
                );
            }
            continue;
        };
        let mut names: Vec<_> = read.flatten().map(|e| e.file_name()).collect();
        names.sort();
        for name in names {
            if config.ignore.iter().any(|i| *i == *name.to_string_lossy()) {
                continue;
            }
            let relative = base.join(&name);
            if skip.contains(&relative) {
                continue;
            }
            entries.push(Entry {
                source: config.home.join(&relative),
                dest: config.target.join(&relative),
            });
        }
    }
    entries
}

#[derive(Clone, Copy, PartialEq)]
pub enum Collisions {
    /// Ask on a terminal; skip when there is nobody to ask.
    Ask,
    Force,
    Skip,
}

pub struct Options {
    pub collisions: Collisions,
    pub pretend: bool,
}

#[derive(Default)]
pub struct Summary {
    pub linked: usize,
    pub identical: usize,
    pub replaced: usize,
    pub skipped: usize,
    pub errors: usize,
}

enum Answer {
    Yes,
    No,
    All,
    Quit,
}

/// Remove whatever is at `path` -- file, link, or whole directory.
fn remove_any(path: &Path) -> io::Result<()> {
    let meta = fs::symlink_metadata(path)?;
    if meta.is_dir() {
        fs::remove_dir_all(path)
    } else {
        fs::remove_file(path)
    }
}

fn show_diff(dest: &Path, source: &Path) {
    if let Ok(link) = fs::read_link(dest) {
        println!("- {}", link.display());
        println!("+ {}", source.display());
        return;
    }
    if dest.is_dir() || source.is_dir() {
        println!("Unable to create diff: destination or content is a directory");
        return;
    }
    let _ = Command::new("diff")
        .arg("-u")
        .arg(dest)
        .arg(source)
        .status();
}

fn ask(dest: &Path, source: &Path) -> Answer {
    let stdin = io::stdin();
    loop {
        print!(
            "Overwrite {}? (enter \"h\" for help) [yNaqdh] ",
            dest.display()
        );
        let _ = io::stdout().flush();
        let mut line = String::new();
        if stdin.lock().read_line(&mut line).unwrap_or(0) == 0 {
            println!();
            return Answer::Quit;
        }
        match line.trim().to_lowercase().as_str() {
            "y" | "yes" => return Answer::Yes,
            "" | "n" | "no" => return Answer::No,
            "a" | "all" => return Answer::All,
            "q" | "quit" => return Answer::Quit,
            "d" | "diff" => show_diff(dest, source),
            _ => {
                println!("y - yes, overwrite");
                println!("n - no, keep what is there (default)");
                println!("a - all, overwrite this and every later conflict");
                println!("q - quit, stop here");
                println!("d - diff, show what would change");
                println!("h - help, show this");
            }
        }
    }
}

/// Never write through a path that lands back inside the repo. If a parent of
/// `dest` is itself a link into the repo (the target's ~/.config linked whole,
/// say), "replacing" `dest` would delete the real file in the repo and leave a
/// link pointing at itself -- exactly how Ruby homesick can wipe out a
/// .homesick_subdir folder.
fn refuse_inside_repo(config: &Config, dest: &Path, ui: &Ui) -> bool {
    let Some(parent) = dest.parent() else {
        return false;
    };
    let Ok(real_parent) = fs::canonicalize(parent) else {
        return false;
    };
    if !(real_parent.starts_with(&config.dir) || real_parent.starts_with(&config.home)) {
        return false;
    }
    ui.status(
        "error",
        Color::Red,
        &format!(
            "refusing {}: {} resolves inside the repo ({})",
            dest.display(),
            parent.display(),
            real_parent.display()
        ),
    );
    true
}

pub fn link(config: &Config, options: &Options, ui: &Ui) -> Summary {
    let mut summary = Summary::default();
    let mut collisions = options.collisions;
    let interactive = io::stdin().is_terminal();

    for entry in plan(config, ui) {
        // Linked to the physical path, as homesick did, so links made by
        // either tool compare identical.
        let source = match fs::canonicalize(&entry.source) {
            Ok(source) => source,
            Err(err) => {
                ui.status(
                    "error",
                    Color::Red,
                    &format!("{}: {err}", entry.source.display()),
                );
                summary.errors += 1;
                continue;
            }
        };
        let dest = &entry.dest;

        if refuse_inside_repo(config, dest, ui) {
            summary.errors += 1;
            continue;
        }

        let existing = fs::symlink_metadata(dest).ok();
        let current_link = fs::read_link(dest).ok();
        match (&existing, &current_link) {
            (None, _) => {
                ui.status(
                    "symlink",
                    Color::Green,
                    &format!("{} to {}", source.display(), dest.display()),
                );
                if !options.pretend {
                    if let Some(parent) = dest.parent()
                        && let Err(err) = fs::create_dir_all(parent)
                    {
                        ui.status("error", Color::Red, &format!("{}: {err}", parent.display()));
                        summary.errors += 1;
                        continue;
                    }
                    if let Err(err) = std::os::unix::fs::symlink(&source, dest) {
                        ui.status("error", Color::Red, &format!("{}: {err}", dest.display()));
                        summary.errors += 1;
                        continue;
                    }
                }
                summary.linked += 1;
                continue;
            }
            (Some(_), Some(link)) if *link == source => {
                ui.status("identical", Color::Blue, &dest.display().to_string());
                summary.identical += 1;
                continue;
            }
            (Some(_), Some(link)) => ui.status(
                "conflict",
                Color::Red,
                &format!("{} exists and points to {}", dest.display(), link.display()),
            ),
            (Some(_), None) => ui.status(
                "conflict",
                Color::Red,
                &format!("{} exists", dest.display()),
            ),
        }

        // A conflict: something else is already at `dest`.
        let replace = match collisions {
            Collisions::Force => true,
            Collisions::Skip => false,
            Collisions::Ask if !interactive => {
                ui.status(
                    "skip",
                    Color::Yellow,
                    "not a terminal; pass --force to replace it",
                );
                false
            }
            Collisions::Ask => match ask(dest, &source) {
                Answer::Yes => true,
                Answer::No => false,
                Answer::All => {
                    collisions = Collisions::Force;
                    true
                }
                Answer::Quit => {
                    ui.status(
                        "quit",
                        Color::Yellow,
                        "stopping; nothing further was changed",
                    );
                    summary.skipped += 1;
                    return summary;
                }
            },
        };

        if !replace {
            ui.status("skip", Color::Yellow, &dest.display().to_string());
            summary.skipped += 1;
            continue;
        }

        ui.status(
            "force",
            Color::Yellow,
            &format!("{} to {}", source.display(), dest.display()),
        );
        if !options.pretend {
            let result = remove_any(dest).and_then(|_| std::os::unix::fs::symlink(&source, dest));
            if let Err(err) = result {
                ui.status("error", Color::Red, &format!("{}: {err}", dest.display()));
                summary.errors += 1;
                continue;
            }
        }
        summary.replaced += 1;
    }
    summary
}

/// Remove the links `link` made. Only a symlink that points back into the
/// repo is removed; homesick removed any symlink it found, which could take
/// out a link some other tool had put there. --force restores that.
pub fn unlink(config: &Config, options: &Options, ui: &Ui) -> Summary {
    let mut summary = Summary::default();
    for entry in plan(config, ui) {
        let dest = &entry.dest;
        if refuse_inside_repo(config, dest, ui) {
            summary.errors += 1;
            continue;
        }
        let Ok(link) = fs::read_link(dest) else {
            if fs::symlink_metadata(dest).is_ok() {
                ui.status(
                    "conflict",
                    Color::Red,
                    &format!("{} is not a symlink", dest.display()),
                );
                summary.skipped += 1;
            } else {
                ui.status("missing", Color::Blue, &dest.display().to_string());
            }
            continue;
        };

        let source = fs::canonicalize(&entry.source).unwrap_or(entry.source.clone());
        let ours = link == source || link == entry.source || link.starts_with(&config.dir);
        if !ours && options.collisions != Collisions::Force {
            ui.status(
                "conflict",
                Color::Red,
                &format!(
                    "{} points to {}, not this repo (--force removes it anyway)",
                    dest.display(),
                    link.display()
                ),
            );
            summary.skipped += 1;
            continue;
        }

        ui.status("unlink", Color::Green, &dest.display().to_string());
        if !options.pretend
            && let Err(err) = fs::remove_file(dest)
        {
            ui.status("error", Color::Red, &format!("{}: {err}", dest.display()));
            summary.errors += 1;
            continue;
        }
        summary.linked += 1;
    }
    summary
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::config::Config;
    use std::os::unix::fs::symlink;

    fn setup() -> (tempfile::TempDir, Config) {
        let root = tempfile::tempdir().unwrap();
        let dir = fs::canonicalize(root.path()).unwrap();
        let repo = dir.join("repo");
        let home = repo.join("home");
        let target = dir.join("target");
        fs::create_dir_all(home.join(".config/direnv")).unwrap();
        fs::create_dir_all(home.join("Library/Application Support/App")).unwrap();
        fs::create_dir_all(home.join("bin")).unwrap();
        fs::create_dir_all(&target).unwrap();
        fs::write(home.join(".bashrc"), "x").unwrap();
        fs::write(home.join(".DS_Store"), "x").unwrap();
        fs::write(home.join(".config/starship.toml"), "x").unwrap();
        fs::write(
            repo.join(".homesick_subdir"),
            ".config\n\nLibrary/Application Support/\n",
        )
        .unwrap();
        let config = Config {
            dir: repo.clone(),
            dir_source: "test".into(),
            home,
            target,
            ignore: vec![".DS_Store".into(), ".git".into()],
            config_file: dir.join("none.toml"),
            config_file_exists: false,
        };
        (root, config)
    }

    fn rel(config: &Config, entries: &[Entry]) -> Vec<String> {
        entries
            .iter()
            .map(|e| {
                e.dest
                    .strip_prefix(&config.target)
                    .unwrap()
                    .display()
                    .to_string()
            })
            .collect()
    }

    #[test]
    fn plan_honors_subdirs_and_ancestors() {
        let (_root, config) = setup();
        let ui = Ui::silent();
        let entries = plan(&config, &ui);
        assert_eq!(
            rel(&config, &entries),
            vec![
                ".bashrc",
                "bin",
                ".config/direnv",
                ".config/starship.toml",
                "Library/Application Support/App",
            ]
        );
    }

    #[test]
    fn link_is_idempotent_and_respects_conflicts() {
        let (_root, config) = setup();
        let ui = Ui::silent();
        fs::write(config.target.join(".bashrc"), "mine").unwrap();
        let skip = Options {
            collisions: Collisions::Skip,
            pretend: false,
        };

        let first = link(&config, &skip, &ui);
        assert_eq!((first.linked, first.skipped), (4, 1));
        assert!(fs::read_link(config.target.join(".config/direnv")).is_ok());
        assert_eq!(
            fs::read_to_string(config.target.join(".bashrc")).unwrap(),
            "mine"
        );

        let again = link(&config, &skip, &ui);
        assert_eq!((again.identical, again.linked), (4, 0));

        let force = Options {
            collisions: Collisions::Force,
            pretend: false,
        };
        let forced = link(&config, &force, &ui);
        assert_eq!(forced.replaced, 1);
        assert_eq!(
            fs::read_link(config.target.join(".bashrc")).unwrap(),
            config.home.join(".bashrc")
        );
    }

    #[test]
    fn pretend_changes_nothing() {
        let (_root, config) = setup();
        let ui = Ui::silent();
        let options = Options {
            collisions: Collisions::Force,
            pretend: true,
        };
        let summary = link(&config, &options, &ui);
        assert_eq!(summary.linked, 5);
        assert_eq!(fs::read_dir(&config.target).unwrap().count(), 0);
    }

    #[test]
    fn unlink_leaves_foreign_links() {
        let (_root, config) = setup();
        let ui = Ui::silent();
        let options = Options {
            collisions: Collisions::Skip,
            pretend: false,
        };
        link(&config, &options, &ui);
        fs::remove_file(config.target.join("bin")).unwrap();
        symlink("/usr/bin", config.target.join("bin")).unwrap();

        let summary = unlink(&config, &options, &ui);
        assert_eq!((summary.linked, summary.skipped), (4, 1));
        assert!(fs::read_link(config.target.join("bin")).is_ok());
        assert!(fs::symlink_metadata(config.target.join(".bashrc")).is_err());
    }

    #[test]
    fn refuses_to_write_through_a_link_into_the_repo() {
        let (_root, config) = setup();
        let ui = Ui::silent();
        // The failure mode that wiped the real repo: the target's .config is
        // a link to the repo's own .config.
        symlink(config.home.join(".config"), config.target.join(".config")).unwrap();
        let force = Options {
            collisions: Collisions::Force,
            pretend: false,
        };
        let summary = link(&config, &force, &ui);
        assert_eq!(summary.errors, 2);
        assert!(config.home.join(".config/direnv").is_dir());
        assert!(fs::read_link(config.home.join(".config/direnv")).is_err());
        assert_eq!(
            fs::read_to_string(config.home.join(".config/starship.toml")).unwrap(),
            "x"
        );

        let summary = unlink(&config, &force, &ui);
        assert_eq!(summary.errors, 2);
        assert!(config.home.join(".config/starship.toml").is_file());
    }
}
