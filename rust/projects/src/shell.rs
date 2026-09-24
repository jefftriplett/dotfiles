//! workon and mkproject, as shell code for a thin bash wrapper to eval.
//!
//! Both have to change the calling shell -- cd into the project, source its
//! virtualenv -- which no child process can do. So every decision is made
//! here, and what comes out on stdout is the handful of shell lines that act
//! on it. The wrappers in ~/.bashrc.d/61-workon.bash are just:
//!
//!     code="$(command projects workon "$@")" || return $?
//!     eval "$code"
//!
//! Errors go to stderr with a non-zero exit and no code at all, so a failed
//! lookup never evals half an answer. Anything meant for the terminal (help,
//! the project list) is emitted as a printf, so it prints when eval'd.

use std::collections::BTreeSet;
use std::env;
use std::fs;
use std::path::{Path, PathBuf};

use crate::commands::{Result, load};
use crate::registry::{Plan, Registry, registry_path};
use crate::util::{expand_str, fail, home, quote};

const WORKON_USAGE: &str = "\
Usage: workon [--auto|--local|--remote] [--host=MACHINE] [--tmux] <project>

  workon notes                open it wherever the registry says it lives
  workon --local=pghub        force a local cd + activate
  workon --remote=pghub       force a mosh to its registered machine
  workon --host=studio pghub  open it on the Studio instead, just this once
  workon --list               list registered projects
  workon --sessions           show live tmux sessions on every Mac
  workon -s --kill notes      kill a session, by project key or session name

--sessions passes its remaining arguments to `projects sessions`, so
`workon -s -a` is attached sessions only and `workon -s -m studio` is one Mac.
--kill asks before it kills; add -y to skip that.

Local opens cd and activate the virtualenv. Add --tmux (or export WORKON_TMUX=1)
to attach a tmux session locally too; remote opens always attach one.
";

const MKPROJECT_USAGE: &str = "\
Usage: mkproject <name> [--machine KEY] [--host KEY] [--path DIR] [--work]
                            [--session NAME] [--tmux|--no-tmux]
                            [--python VERSION] [--no-attach] [--dry-run]

Creates the directory, a uv venv, and an .envrc (layout uv + use tmux) here,
registers it in ~/Projects/projects.toml, then opens it with workon. Syncthing
carries the directory to the other Macs; --machine only says which one owns it.

--work puts it under work_dir instead of home_dir; --path overrides both. No
machine is recorded unless you pass --machine, and a project without one opens
wherever you are.

--no-tmux registers the project with tmux off and leaves `use tmux` out of the
.envrc, so it is a plain cd + activate everywhere. --session names the session
when the project key is not what you want tmux to show.
";

/// Directories searched for projects that are not in the registry.
fn project_dirs() -> [PathBuf; 2] {
    [home().join("Projects"), home().join("Work")]
}

/// Shell code that prints `text` verbatim.
fn print_code(text: &str, stderr: bool) -> String {
    let redirect = if stderr { " >&2" } else { "" };
    format!("printf '%s' {}{redirect}\n", quote(text))
}

fn emit(code: &str) {
    print!("{code}");
}

fn subdirs(dir: &Path) -> Vec<String> {
    let Ok(entries) = fs::read_dir(dir) else {
        return Vec::new();
    };
    entries
        .flatten()
        .filter(|entry| entry.path().is_dir())
        .map(|entry| entry.file_name().to_string_lossy().into_owned())
        .collect()
}

/// Every name workon can open: registered projects, then any unregistered
/// directory, then bare ~/.virtualenvs. The Python version cached this for
/// completion because `projects list` took ~300ms to start; this takes a few
/// milliseconds, so it is simply computed every time.
pub fn all_names() -> Vec<String> {
    let mut names = BTreeSet::new();
    if let Ok(registry) = registry_path().and_then(Registry::load) {
        names.extend(registry.projects.keys().cloned());
    }
    for dir in project_dirs() {
        names.extend(subdirs(&dir));
    }
    let venvs = home().join(".virtualenvs");
    names.extend(
        subdirs(&venvs)
            .into_iter()
            .filter(|name| venvs.join(name).join("bin/activate").is_file()),
    );
    names.into_iter().collect()
}

#[derive(PartialEq)]
enum Mode {
    Auto,
    Local,
    Remote,
}

pub fn workon(args: &[String]) -> Result {
    let mut mode = Mode::Auto;
    let mut name = String::new();
    let mut host = String::new();
    let mut want_tmux = env::var("WORKON_TMUX").unwrap_or_default() == "1";

    let mut args = args.iter();
    while let Some(arg) = args.next() {
        let value = arg.split_once('=').map(|(_, value)| value.to_string());
        match arg.as_str() {
            "-h" | "--help" => {
                emit(&print_code(WORKON_USAGE, false));
                return Ok(());
            }
            "-l" | "--list" => {
                emit(&print_list(&all_names()));
                return Ok(());
            }
            "-s" | "--sessions" => {
                // Everything after this is for `projects sessions`.
                let rest: Vec<&str> = args.map(String::as_str).collect();
                let mut argv = vec!["command", "projects", "sessions"];
                argv.extend(rest);
                emit(&format!("{}\n", shell_words(&argv)));
                return Ok(());
            }
            "--auto" => mode = Mode::Auto,
            "--local" => mode = Mode::Local,
            "--remote" => mode = Mode::Remote,
            "--host" | "--machine" => match args.next() {
                Some(value) if !value.is_empty() => host = value.clone(),
                _ => {
                    fail("workon: --host needs a machine name");
                    return Err(2);
                }
            },
            "--tmux" => want_tmux = true,
            "--no-tmux" => want_tmux = false,
            _ if arg.starts_with("--auto=") => {
                mode = Mode::Auto;
                name = value.unwrap_or_default();
            }
            _ if arg.starts_with("--local=") => {
                mode = Mode::Local;
                name = value.unwrap_or_default();
            }
            _ if arg.starts_with("--remote=") => {
                mode = Mode::Remote;
                name = value.unwrap_or_default();
            }
            _ if arg.starts_with("--host=") || arg.starts_with("--machine=") => {
                host = value.unwrap_or_default();
            }
            _ if arg.starts_with('-') => {
                fail(&format!("workon: unknown option: {arg}"));
                eprint!("{WORKON_USAGE}");
                return Err(2);
            }
            _ => {
                if name.is_empty() {
                    name = arg.clone();
                } else {
                    fail(&format!("workon: unexpected argument: {arg}"));
                    return Err(2);
                }
            }
        }
    }

    if name.is_empty() {
        let listing: Vec<String> = all_names().iter().map(|n| format!("  {n}")).collect();
        let text = format!("{WORKON_USAGE}\nProjects:\n");
        emit(&print_code(&text, false));
        emit(&print_list(&listing));
        emit("return 1\n");
        return Ok(());
    }

    let registry = load()?;
    let Some(project) = registry.project(&name).cloned() else {
        // Not in the registry. --remote and --host have nothing to work
        // from, so they are an error rather than a silent local open.
        if mode == Mode::Remote || !host.is_empty() {
            fail(&format!(
                "workon: {name} is not in the registry, so it has no machine."
            ));
            eprintln!("Register it with: projects add {}", quote(&name));
            return Err(1);
        }
        return local_fallback(&name);
    };

    // --host is a one-off "open it over there", never written back.
    let mut project = project;
    if !host.is_empty() {
        let target = registry.machine(Some(&host)).ok_or_else(|| {
            fail(&format!("Unknown machine: {host}"));
            1
        })?;
        project.machine = Some(target.key.clone());
    }

    let plan = registry.plan(&project).map_err(|err| {
        fail(&err);
        1
    })?;

    // A project with `tmux = false` stays a plain cd + activate even when
    // asked for a session, since it has deliberately opted out of one.
    if !plan.tmux {
        want_tmux = false;
    }

    match mode {
        Mode::Local => return open_local(&plan, want_tmux),
        Mode::Remote if plan.local => {
            match &plan.machine {
                Some(machine) => fail(&format!(
                    "workon: {} is registered to this machine ({}).",
                    plan.project.key, machine.key
                )),
                None => {
                    fail(&format!(
                        "workon: {} has no machine, so it opens wherever you are.",
                        plan.project.key
                    ));
                    eprintln!(
                        "Give it one with: projects set {} --machine <machine>",
                        quote(&plan.project.key)
                    );
                }
            }
            eprintln!("Use --host=<machine> to open it somewhere else.");
            return Err(1);
        }
        _ => {}
    }

    if plan.local {
        open_local(&plan, want_tmux)
    } else {
        open_remote(&plan)
    }
}

fn print_list<S: AsRef<str>>(lines: &[S]) -> String {
    if lines.is_empty() {
        return String::new();
    }
    let words: Vec<String> = lines.iter().map(|l| quote(l.as_ref())).collect();
    format!("printf '%s\\n' {}\n", words.join(" "))
}

fn shell_words(argv: &[&str]) -> String {
    argv.iter()
        .map(|word| quote(word))
        .collect::<Vec<_>>()
        .join(" ")
}

/// cd in, then either attach tmux or activate the virtualenv.
fn open_local(plan: &Plan, want_tmux: bool) -> Result {
    let name = &plan.project.key;
    let path = expand_str(&plan.path);
    if !Path::new(&path).is_dir() {
        fail(&format!(
            "workon: {name} is registered here but {path} does not exist"
        ));
        eprintln!(
            "Fix it with: projects add {} --force --path ...",
            quote(name)
        );
        return Err(1);
    }

    let mut code = format!("cd -- {} || return 1\n", quote(&path));
    if want_tmux {
        // In a subshell, and with both host variables unset: the registry
        // says this project is local, so a TMUX_AUTOATTACH_HOST left over
        // from the directory we came from must not send tmux-go over the
        // network.
        code += &format!(
            "(unset TMUX_AUTOATTACH_HOST TMUX_AUTOATTACH_MACHINE; \
             export TMUX_AUTOATTACH_PATH={}; tmux-go {})\n",
            quote(&path),
            quote(&plan.session)
        );
    } else {
        code += &activate_code(Path::new(&path), name);
    }
    emit(&code);
    Ok(())
}

/// Mosh (or ssh) to the machine and attach the session.
fn open_remote(plan: &Plan) -> Result {
    let Some(machine) = &plan.machine else {
        fail("workon: no machine to reach");
        return Err(1);
    };
    if plan.argv.is_empty() {
        fail(&format!("workon: no command to reach {}", machine.host));
        return Err(1);
    }
    let title = format!("{}:{}", machine.key, plan.session);
    let mut code = format!("printf '\\033]0;%s\\007' {}\n", quote(&title));
    code += &print_code(
        &format!(
            "workon: {} on {} ({})\n",
            plan.project.key, machine.key, machine.host
        ),
        true,
    );
    // direnv exec / so the current project's direnv environment (which may
    // export TMUX_AUTOATTACH and re-trigger an attach) is out of the way.
    let argv: Vec<&str> = plan.argv.iter().map(String::as_str).collect();
    code += &format!("direnv exec / {}\n", shell_words(&argv));
    emit(&code);
    Ok(())
}

/// Unregistered projects: the original directory scan, then a bare
/// ~/.virtualenvs/<name>.
fn local_fallback(name: &str) -> Result {
    for dir in project_dirs() {
        let project_dir = dir.join(name);
        if project_dir.is_dir() {
            let path = project_dir.to_string_lossy();
            let mut code = format!("cd -- {} || return 1\n", quote(&path));
            code += &activate_code(&project_dir, name);
            emit(&code);
            return Ok(());
        }
    }

    let venv = home().join(".virtualenvs").join(name);
    if venv.join("bin/activate").is_file() {
        let mut code = source_code(&venv);
        let src = venv.join("src");
        if src.is_dir() {
            code += &format!("cd -- {} || return 1\n", quote(&src.to_string_lossy()));
        }
        code += &format!(
            "echo {}\n",
            quote(&format!("Activated: {name} ({})", venv.display()))
        );
        emit(&code);
        return Ok(());
    }

    let dirs: Vec<String> = project_dirs()
        .iter()
        .map(|d| d.display().to_string())
        .collect();
    fail(&format!("workon: project not found: {name}"));
    eprintln!(
        "Searched the registry, {}, and ~/.virtualenvs/",
        dirs.join(" ")
    );
    Err(1)
}

fn source_code(venv: &Path) -> String {
    format!(
        "if [[ -n \"${{VIRTUAL_ENV:-}}\" ]]; then deactivate 2>/dev/null; fi\n\
         source {}\n",
        quote(&venv.join("bin/activate").to_string_lossy())
    )
}

/// Activate the first virtualenv found for a project, in the calling shell.
fn activate_code(project_dir: &Path, name: &str) -> String {
    let candidates = [
        project_dir.join(".venv"),
        project_dir.join("venv"),
        project_dir.join("env"),
        home().join(".virtualenvs").join(name),
    ];
    for venv in candidates {
        if venv.join("bin/activate").is_file() {
            return format!(
                "{}echo {}\n",
                source_code(&venv),
                quote(&format!("Activated: {name} ({})", venv.display()))
            );
        }
    }
    format!(
        "echo {}\n",
        quote(&format!("No virtualenv found for: {name}"))
    )
}

/// mkproject: create, register, then open it with workon.
pub fn mkproject(args: &[String]) -> Result {
    let mut name = String::new();
    let mut attach = true;
    let mut create_args: Vec<String> = Vec::new();

    let mut args = args.iter();
    while let Some(arg) = args.next() {
        match arg.as_str() {
            "-h" | "--help" => {
                emit(&print_code(MKPROJECT_USAGE, false));
                return Ok(());
            }
            "--no-attach" => attach = false,
            "--dry-run" | "-n" => {
                attach = false;
                create_args.push(arg.clone());
            }
            "--host" => match args.next() {
                Some(value) => {
                    create_args.push("--machine".into());
                    create_args.push(value.clone());
                }
                None => {
                    fail("mkproject: --host needs a machine name");
                    return Err(2);
                }
            },
            _ if arg.starts_with("--host=") => {
                create_args.push("--machine".into());
                create_args.push(arg["--host=".len()..].to_string());
            }
            _ if arg.starts_with('-') => create_args.push(arg.clone()),
            _ if name.is_empty() => name = arg.clone(),
            _ => create_args.push(arg.clone()),
        }
    }

    if name.is_empty() {
        fail("Usage: mkproject <name> [options]  (--help for details)");
        return Err(1);
    }

    let mut argv = vec!["command", "projects", "create", name.as_str()];
    argv.extend(create_args.iter().map(String::as_str));
    let mut code = format!("{} || return $?\n", shell_words(&argv));
    if attach {
        code += &format!("workon {}\n", quote(&name));
    }
    emit(&code);
    Ok(())
}
