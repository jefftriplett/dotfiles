//! homesick-new: homesick's symlink behavior, without castles.
//!
//! One dotfiles repo, which can live anywhere (see config.rs for how it is
//! found). Its `home/` folder is mirrored into $HOME as symlinks, with
//! .homesick_subdir naming the folders whose contents are linked one by one.
//! The git conveniences homesick wrapped (status, diff, pull, push, commit)
//! run against that one repo.
//!
//! Dropped from homesick: castles (clone-by-name, list, generate, destroy,
//! exec_all) and `rc`, which evaluated a Ruby .homesickrc.

mod config;
mod linker;
mod ui;

use std::env;
use std::fs;
use std::io::Write;
use std::path::Path;
use std::process::{Command, ExitCode};

use clap::{Args, Parser, Subcommand};

use config::Config;
use linker::{Collisions, Options};
use ui::{Color, Ui};

#[derive(Parser)]
#[command(
    name = "homesick-new",
    version,
    about = "Symlink a dotfiles repo into $HOME (homesick, without castles)"
)]
struct Cli {
    #[command(flatten)]
    global: Global,
    #[command(subcommand)]
    command: Cmd,
}

#[derive(Args)]
struct Global {
    /// Dotfiles repo [env: HOMESICK_DIR, HOMESICK_REPO; config: dir]
    #[arg(long, short = 'd', global = true, value_name = "PATH")]
    dir: Option<String>,
    /// Where links are created [default: $HOME; config: target]
    #[arg(long, global = true, value_name = "PATH")]
    target: Option<String>,
    /// Overwrite files that already exist
    #[arg(long, short = 'f', global = true, conflicts_with = "skip")]
    force: bool,
    /// Skip files that already exist
    #[arg(long, short = 's', global = true)]
    skip: bool,
    /// Show what would change without changing anything
    #[arg(
        long = "dry-run",
        short = 'n',
        global = true,
        visible_alias = "pretend",
        visible_short_alias = 'p'
    )]
    pretend: bool,
    /// Suppress status output
    #[arg(long, short = 'q', global = true)]
    quiet: bool,
}

#[derive(Subcommand)]
enum Cmd {
    /// Symlink every dotfile into $HOME
    #[command(visible_alias = "symlink")]
    Link {
        /// Ignored: there are no castles, only the one repo
        #[arg(hide = true)]
        castle: Option<String>,
    },
    /// Remove the symlinks `link` created
    Unlink {
        #[arg(hide = true)]
        castle: Option<String>,
    },
    /// Move a file from $HOME into the repo and link it back
    Track {
        /// File or directory under $HOME
        file: String,
        #[arg(hide = true)]
        castle: Option<String>,
    },
    /// Show the git status of the repo
    Status,
    /// Show the git diff of uncommitted changes
    Diff,
    /// git pull, then update submodules
    Pull,
    /// git push
    Push,
    /// Commit every change (opens $EDITOR without a message)
    Commit { message: Option<String> },
    /// Clone a dotfiles repo to the configured location
    Clone { uri: String },
    /// Open a new shell in the repo
    Cd,
    /// Open $EDITOR in the repo
    Open,
    /// Run a shell command in the repo
    Exec {
        #[arg(required = true, trailing_var_arg = true, allow_hyphen_values = true)]
        command: Vec<String>,
    },
    /// Print the repo path
    #[command(name = "show_path", visible_alias = "show-path")]
    ShowPath,
    /// Show where the repo, mirror, and target resolved from
    Config,
}

fn collisions(global: &Global) -> Collisions {
    if global.force {
        Collisions::Force
    } else if global.skip {
        Collisions::Skip
    } else {
        Collisions::Ask
    }
}

fn warn_castle(castle: &Option<String>, ui: &Ui) {
    if let Some(castle) = castle {
        ui.status(
            "note",
            Color::Yellow,
            &format!("ignoring castle {castle:?}: there is only the one repo"),
        );
    }
}

/// Run a command in the repo, the way homesick's `system` did: skipped under
/// --dry-run, with a status line first.
fn run_in(
    config: &Config,
    global: &Global,
    ui: &Ui,
    label: &str,
    argv: &[&str],
) -> Result<(), String> {
    ui.status(label, Color::Green, "");
    if global.pretend {
        return Ok(());
    }
    let status = Command::new(argv[0])
        .args(&argv[1..])
        .current_dir(&config.dir)
        .status()
        .map_err(|err| format!("{}: {err}", argv[0]))?;
    if status.success() {
        Ok(())
    } else {
        Err(format!(
            "`{}` exited {}",
            argv.join(" "),
            status.code().unwrap_or(1)
        ))
    }
}

fn shell_in(config: &Config, global: &Global, command: &str) -> Result<(), String> {
    if global.pretend {
        return Ok(());
    }
    let status = Command::new("sh")
        .arg("-c")
        .arg(command)
        .current_dir(&config.dir)
        .status()
        .map_err(|err| err.to_string())?;
    if status.success() {
        Ok(())
    } else {
        Err(format!("`{command}` exited {}", status.code().unwrap_or(1)))
    }
}

fn mtime(path: &Path) -> Option<std::time::SystemTime> {
    fs::symlink_metadata(path).and_then(|m| m.modified()).ok()
}

/// Add `relative_dir` to .homesick_subdir unless it is already listed.
fn subdir_add(
    config: &Config,
    relative_dir: &Path,
    global: &Global,
    ui: &Ui,
) -> Result<(), String> {
    let line = relative_dir.display().to_string();
    if config.subdirs().contains(&line) {
        return Ok(());
    }
    ui.status(
        "subdir",
        Color::Green,
        &format!("{line} added to .homesick_subdir"),
    );
    if global.pretend {
        return Ok(());
    }
    let path = config.subdir_file();
    let mut text = fs::read_to_string(&path).unwrap_or_default();
    if !text.is_empty() && !text.ends_with('\n') {
        text.push('\n');
    }
    text.push_str(&line);
    text.push('\n');
    fs::write(&path, text).map_err(|err| format!("{}: {err}", path.display()))?;
    run_in(
        config,
        global,
        ui,
        "git add",
        &["git", "add", "--", &path.to_string_lossy()],
    )
}

/// Move `file` into the repo's mirror at the same relative path, link it back,
/// and `git add` it. Something nested (~/.config/foo) also puts its parent in
/// .homesick_subdir, so the parent stays a real directory.
fn track(config: &Config, file: &str, global: &Global, ui: &Ui) -> Result<(), String> {
    config.require_home()?;
    let file = file.trim_end_matches('/');
    let absolute = std::path::absolute(file).map_err(|err| err.to_string())?;

    let relative = absolute
        .strip_prefix(&config.target)
        .or_else(|_| absolute.strip_prefix(config::home()))
        .map_err(|_| {
            format!(
                "{} is not under {}",
                absolute.display(),
                config.target.display()
            )
        })?
        .to_path_buf();
    let meta =
        fs::symlink_metadata(&absolute).map_err(|err| format!("{}: {err}", absolute.display()))?;
    if meta.file_type().is_symlink()
        && let Ok(link) = fs::read_link(&absolute)
        && link.starts_with(&config.dir)
    {
        ui.status(
            "identical",
            Color::Blue,
            &format!("{} is already tracked", absolute.display()),
        );
        return Ok(());
    }

    let relative_dir = relative.parent().map(Path::to_path_buf).unwrap_or_default();
    let repo_dir = config.home.join(&relative_dir);
    let repo_path = repo_dir.join(relative.file_name().unwrap_or_default());

    if fs::symlink_metadata(&repo_path).is_ok() {
        if meta.is_dir() {
            return Err(format!(
                "{} is already in the repo; merge {} into it by hand, then run link",
                repo_path.display(),
                absolute.display()
            ));
        }
        let newer = matches!((mtime(&absolute), mtime(&repo_path)), (Some(a), Some(b)) if a > b);
        if !newer && !global.force {
            ui.status(
                "track",
                Color::Blue,
                &format!(
                    "{} already exists, and is more recent than {}. Run `homesick-new link` to create symlinks.",
                    repo_path.display(),
                    absolute.display()
                ),
            );
            return Ok(());
        }
        ui.status(
            "conflict",
            Color::Red,
            &format!(
                "{} replaced by the newer {}",
                repo_path.display(),
                absolute.display()
            ),
        );
        if !global.pretend {
            fs::remove_file(&repo_path).map_err(|err| err.to_string())?;
        }
    }

    ui.status(
        "move",
        Color::Green,
        &format!("{} to {}", absolute.display(), repo_path.display()),
    );
    ui.status(
        "symlink",
        Color::Green,
        &format!("{} to {}", repo_path.display(), absolute.display()),
    );
    if !global.pretend {
        fs::create_dir_all(&repo_dir).map_err(|err| format!("{}: {err}", repo_dir.display()))?;
        fs::rename(&absolute, &repo_path)
            .map_err(|err| format!("could not move {} into the repo: {err}", absolute.display()))?;
        let source = fs::canonicalize(&repo_path).unwrap_or(repo_path.clone());
        std::os::unix::fs::symlink(&source, &absolute)
            .map_err(|err| format!("{}: {err}", absolute.display()))?;
    }
    run_in(
        config,
        global,
        ui,
        "git add",
        &["git", "add", "--", &repo_path.to_string_lossy()],
    )?;

    if !relative_dir.as_os_str().is_empty() {
        subdir_add(config, &relative_dir, global, ui)?;
    }
    Ok(())
}

fn print_config(config: &Config) {
    let file_note = if config.config_file_exists {
        ""
    } else {
        " (not present)"
    };
    println!(
        "dir          {}  [{}]",
        config.dir.display(),
        config.dir_source
    );
    println!("mirror       {}", config.home.display());
    println!("target       {}", config.target.display());
    println!("subdirs      {}", config.subdirs().join(", "));
    println!("ignore       {}", config.ignore.join(", "));
    println!("config file  {}{file_note}", config.config_file.display());
}

fn run(cli: Cli) -> Result<bool, String> {
    let global = &cli.global;
    let ui = Ui::new(global.quiet);
    let config = config::resolve(global.dir.as_deref(), global.target.as_deref())?;
    let options = Options {
        collisions: collisions(global),
        pretend: global.pretend,
    };

    match &cli.command {
        Cmd::Link { castle } => {
            warn_castle(castle, &ui);
            config.require_home()?;
            let summary = linker::link(&config, &options, &ui);
            Ok(summary.errors == 0)
        }
        Cmd::Unlink { castle } => {
            warn_castle(castle, &ui);
            config.require_home()?;
            let summary = linker::unlink(&config, &options, &ui);
            Ok(summary.errors == 0)
        }
        Cmd::Track { file, castle } => {
            warn_castle(castle, &ui);
            track(&config, file, global, &ui).map(|_| true)
        }
        Cmd::Status => run_in(&config, global, &ui, "git status", &["git", "status"]).map(|_| true),
        Cmd::Diff => run_in(&config, global, &ui, "git diff", &["git", "diff"]).map(|_| true),
        Cmd::Pull => {
            run_in(
                &config,
                global,
                &ui,
                "git pull",
                &["git", "pull", "--quiet"],
            )?;
            if config.dir.join(".gitmodules").exists() {
                run_in(
                    &config,
                    global,
                    &ui,
                    "git submodule",
                    &[
                        "git",
                        "submodule",
                        "--quiet",
                        "update",
                        "--init",
                        "--recursive",
                    ],
                )?;
            }
            Ok(true)
        }
        Cmd::Push => run_in(&config, global, &ui, "git push", &["git", "push"]).map(|_| true),
        Cmd::Commit { message } => {
            let argv: Vec<&str> = match message {
                Some(message) => vec!["git", "commit", "-a", "-m", message],
                None => vec!["git", "commit", "-v", "-a"],
            };
            run_in(&config, global, &ui, "git commit all", &argv).map(|_| true)
        }
        Cmd::Clone { uri } => {
            if config.dir.exists() {
                return Err(format!(
                    "{} already exists; pass --dir to clone somewhere else",
                    config.dir.display()
                ));
            }
            ui.status(
                "git clone",
                Color::Green,
                &format!("{uri} to {}", config.dir.display()),
            );
            if !global.pretend {
                let status = Command::new("git")
                    .args(["clone", "--recursive", uri])
                    .arg(&config.dir)
                    .status()
                    .map_err(|err| format!("git: {err}"))?;
                if !status.success() {
                    return Err("git clone failed".into());
                }
            }
            ui.status("next", Color::Blue, "homesick-new link");
            Ok(true)
        }
        Cmd::Cd => {
            let shell = env::var("SHELL").unwrap_or_else(|_| "/bin/sh".into());
            ui.status(
                &format!("cd {}", config.dir.display()),
                Color::Green,
                "Opening a new shell in the repo. Exit it to return.",
            );
            if !global.pretend {
                Command::new(&shell)
                    .current_dir(&config.dir)
                    .status()
                    .map_err(|err| format!("{shell}: {err}"))?;
            }
            Ok(true)
        }
        Cmd::Open => {
            let editor = env::var("EDITOR")
                .ok()
                .filter(|e| !e.is_empty())
                .ok_or("The $EDITOR environment variable must be set to use this command")?;
            ui.status(
                &format!("{}: {editor} .", config.dir.display()),
                Color::Green,
                "",
            );
            shell_in(&config, global, &format!("{editor} .")).map(|_| true)
        }
        Cmd::Exec { command } => {
            let command = command.join(" ");
            let verb = if global.pretend {
                "Would execute"
            } else {
                "Executing command"
            };
            ui.status(
                &format!("exec '{command}'"),
                Color::Green,
                &format!("{verb} '{command}' in {}", config.dir.display()),
            );
            shell_in(&config, global, &command).map(|_| true)
        }
        Cmd::ShowPath => {
            println!("{}", config.dir.display());
            Ok(true)
        }
        Cmd::Config => {
            print_config(&config);
            Ok(true)
        }
    }
}

fn main() -> ExitCode {
    let cli = Cli::parse();
    let result = run(cli);
    let _ = std::io::stdout().flush();
    match result {
        Ok(true) => ExitCode::SUCCESS,
        Ok(false) => ExitCode::FAILURE,
        Err(message) => {
            eprintln!("homesick-new: {message}");
            ExitCode::FAILURE
        }
    }
}
