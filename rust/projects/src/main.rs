//! projects: a Rust port of ~/bin/projects-archive, plus the logic behind the
//! `workon` and `mkproject` shell functions.
//!
//! Manages the project registry in ~/Projects/projects.toml: which machine
//! each project lives on, where it lives there, and which tmux session holds
//! it. The file format is unchanged, so this and the Python
//! `projects-archive` can be run against the same registry.
//!
//! `workon` and `mkproject` have to change the calling shell (cd, activate a
//! virtualenv), which no child process can do. So the hidden `workon` and
//! `mkproject` subcommands print shell code, and the thin `workon` and
//! `mkproject` functions in ~/.bashrc.d/61-workon.bash eval it.

mod commands;
mod import;
mod registry;
mod shell;
mod tmux;
mod util;

use clap::{Args, Parser, Subcommand};

#[derive(Parser)]
#[command(
    name = "projects",
    about = "Track which machine each project lives on (~/Projects/projects.toml)"
)]
struct Cli {
    #[command(subcommand)]
    command: Option<Command>,
}

/// `--tmux/--no-tmux`: unset unless one is given, and the last one wins.
#[derive(Args, Clone, Copy)]
pub struct TmuxFlag {
    /// Override the default tmux setting for this project
    #[arg(long, overrides_with = "no_tmux")]
    tmux: bool,
    #[arg(long, overrides_with = "tmux", hide_short_help = true)]
    no_tmux: bool,
}

impl TmuxFlag {
    pub fn value(self) -> Option<bool> {
        match (self.tmux, self.no_tmux) {
            (true, _) => Some(true),
            (_, true) => Some(false),
            _ => None,
        }
    }
}

#[derive(Subcommand)]
enum Command {
    /// List registered project names, one per line
    List {
        /// Only projects on this machine
        #[arg(long, short)]
        machine: Option<String>,
        /// Group by machine and show paths and sessions
        #[arg(long, short)]
        long: bool,
        /// Deprecated: bare names are the default; kept so old invocations work
        #[arg(long = "names-only", short = 'q', hide = true)]
        names_only: bool,
    },
    /// Register a project
    Add {
        /// Project name (also the default tmux session)
        name: String,
        /// Machine key; no machine is recorded if omitted
        #[arg(long, short)]
        machine: Option<String>,
        /// Directory on that machine; defaults to <home_dir>/<name>
        #[arg(long, short)]
        path: Option<String>,
        /// Default the path under work_dir, not home_dir
        #[arg(long, short)]
        work: bool,
        /// tmux session name; defaults to NAME
        #[arg(long, short)]
        session: Option<String>,
        #[command(flatten)]
        tmux: TmuxFlag,
        #[arg(long, short)]
        description: Option<String>,
        /// Overwrite an existing entry
        #[arg(long, short)]
        force: bool,
    },
    /// Change one project's details in place
    Set {
        /// Project to edit
        name: String,
        /// Move it to this machine
        #[arg(long, short)]
        machine: Option<String>,
        /// Project directory on that machine
        #[arg(long, short)]
        path: Option<String>,
        /// Checkout inside it the session runs in
        #[arg(long = "tmux-path")]
        tmux_path: Option<String>,
        /// tmux session name
        #[arg(long, short)]
        session: Option<String>,
        #[command(flatten)]
        tmux: TmuxFlag,
        #[arg(long, short)]
        description: Option<String>,
        /// Unset a field: machine, tmux, tmux_path, session, description (repeatable)
        #[arg(long)]
        clear: Vec<String>,
    },
    /// Unregister a project. The directory itself is untouched
    Remove {
        /// Project to unregister
        name: String,
    },
    /// Import ~/Projects and ~/Work into the registry
    Import(import::ImportArgs),
    /// Deprecated alias for `import`
    #[command(hide = true)]
    Scan {
        #[arg(long = "dry-run", short = 'n')]
        dry_run: bool,
    },
    /// Print how to reach a project: machine, path, session, and command
    Resolve {
        /// Project to look up
        name: String,
        /// Resolve as if the project lived on this machine (key or ssh name)
        #[arg(long, short, visible_alias = "host")]
        machine: Option<String>,
        /// Emit `eval`-able assignments
        #[arg(long)]
        shell: bool,
        /// Emit JSON
        #[arg(long)]
        json: bool,
    },
    /// Show the tmux sessions running on every Mac, and what to type to reach one
    Sessions {
        /// Only probe these machines (repeatable)
        #[arg(long, short)]
        machine: Vec<String>,
        /// Only sessions with a client attached
        #[arg(long, short)]
        attached: bool,
        /// Bare project names, one per line, for piping
        #[arg(long, short = 'q')]
        names: bool,
        /// Kill this session (session name or project key)
        #[arg(long, short)]
        kill: Option<String>,
        /// Kill without asking first
        #[arg(long, short)]
        yes: bool,
        /// ssh connect timeout in seconds
        #[arg(long, short, default_value_t = 5)]
        timeout: u64,
    },
    /// Create a project directory with a venv and .envrc, then register it
    Create {
        /// Project to create and register
        name: String,
        /// Machine key; no machine is recorded if omitted
        #[arg(long, short)]
        machine: Option<String>,
        /// Directory; defaults to <home_dir>/<name>
        #[arg(long, short)]
        path: Option<String>,
        /// Create under work_dir, not home_dir
        #[arg(long, short)]
        work: bool,
        /// tmux session name; defaults to NAME
        #[arg(long, short)]
        session: Option<String>,
        #[command(flatten)]
        tmux: TmuxFlag,
        /// Python version for uv venv
        #[arg(long, default_value = "3")]
        python: String,
        /// Print the commands without running them
        #[arg(long = "dry-run", short = 'n')]
        dry_run: bool,
    },
    /// Open the registry in $EDITOR
    Edit,
    /// Create the registry, importing machines from hosts.toml if it exists
    Init {
        /// Rewrite an existing registry's tables
        #[arg(long, short)]
        force: bool,
    },
    /// Add, remove, and list machines
    Machines {
        #[command(subcommand)]
        command: Option<MachinesCommand>,
    },
    /// Every name `workon` can open, for shell completion
    #[command(hide = true)]
    Names,
    /// Shell code for the workon function to eval
    #[command(hide = true, disable_help_flag = true)]
    Workon {
        #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
        args: Vec<String>,
    },
    /// Shell code for the mkproject function to eval
    #[command(hide = true, disable_help_flag = true)]
    Mkproject {
        #[arg(trailing_var_arg = true, allow_hyphen_values = true)]
        args: Vec<String>,
    },
}

#[derive(Subcommand)]
enum MachinesCommand {
    /// List the configured machines
    List,
    /// Add a machine
    Add {
        /// Short name you will type, e.g. studio
        key: String,
        /// ssh name; defaults to the key
        #[arg(long)]
        host: Option<String>,
        /// That machine's own `hostname`, when it differs
        #[arg(long)]
        hostname: Option<String>,
        /// Verify the host answers over ssh first
        #[arg(long)]
        check: bool,
    },
    /// Remove a machine. Refuses while projects still point at it
    Remove {
        /// Machine to remove
        key: String,
    },
}

fn run(cli: Cli) -> commands::Result {
    use commands as c;
    match cli.command {
        None => c::list(None, false, false),
        Some(Command::List {
            machine,
            long,
            names_only,
        }) => c::list(machine.as_deref(), long, names_only),
        Some(Command::Add {
            name,
            machine,
            path,
            work,
            session,
            tmux,
            description,
            force,
        }) => c::locked(|| {
            c::add(c::AddOptions {
                name,
                machine,
                path,
                work,
                session,
                tmux: tmux.value(),
                description,
                force,
            })
        }),
        Some(Command::Set {
            name,
            machine,
            path,
            tmux_path,
            session,
            tmux,
            description,
            clear,
        }) => c::locked(|| {
            c::set(c::SetOptions {
                name,
                machine,
                path,
                tmux_path,
                session,
                tmux: tmux.value(),
                description,
                clear,
            })
        }),
        Some(Command::Remove { name }) => c::locked(|| c::remove(&name)),
        Some(Command::Import(args)) => c::locked(|| import::run(&args)),
        Some(Command::Scan { dry_run }) => {
            util::fail("`projects scan` is now `projects import`; running that.");
            c::locked(|| import::run(&import::ImportArgs::dry_run(dry_run)))
        }
        Some(Command::Resolve {
            name,
            machine,
            shell,
            json,
        }) => c::resolve(&name, machine.as_deref(), shell, json),
        Some(Command::Sessions {
            machine,
            attached,
            names,
            kill,
            yes,
            timeout,
        }) => c::sessions(&machine, attached, names, kill.as_deref(), yes, timeout),
        Some(Command::Create {
            name,
            machine,
            path,
            work,
            session,
            tmux,
            python,
            dry_run,
        }) => c::locked(|| {
            c::create(c::CreateOptions {
                name,
                machine,
                path,
                work,
                session,
                tmux: tmux.value(),
                python,
                dry_run,
            })
        }),
        Some(Command::Edit) => c::edit(),
        Some(Command::Init { force }) => c::locked(|| c::init(force)),
        Some(Command::Machines { command }) => match command {
            None | Some(MachinesCommand::List) => c::machines_list(),
            Some(MachinesCommand::Add {
                key,
                host,
                hostname,
                check,
            }) => c::locked(|| c::machines_add(&key, host, hostname, check)),
            Some(MachinesCommand::Remove { key }) => c::locked(|| c::machines_remove(&key)),
        },
        Some(Command::Names) => {
            for name in shell::all_names() {
                println!("{name}");
            }
            Ok(())
        }
        Some(Command::Workon { args }) => shell::workon(&args),
        Some(Command::Mkproject { args }) => shell::mkproject(&args),
    }
}

fn main() {
    // Rust ignores SIGPIPE by default, which turns `projects list | head`
    // into a panic on the first write after head exits. Restore the default so
    // it exits quietly, the way a pipeline expects.
    // SAFETY: called before any threads are spawned.
    unsafe {
        libc::signal(libc::SIGPIPE, libc::SIG_DFL);
    }
    let cli = Cli::parse();
    if let Err(code) = run(cli) {
        std::process::exit(code);
    }
}
