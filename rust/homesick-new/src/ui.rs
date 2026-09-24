//! Thor-style status lines: a right-aligned coloured verb, then the detail.
//!
//!    identical  /Users/you/.bashrc
//!      symlink  /Users/you/repo/home/bin to /Users/you/bin

use std::env;
use std::io::IsTerminal;

#[derive(Clone, Copy)]
pub enum Color {
    Red,
    Green,
    Yellow,
    Blue,
}

pub struct Ui {
    quiet: bool,
    color: bool,
}

impl Ui {
    pub fn new(quiet: bool) -> Ui {
        let no_color = env::var_os("NO_COLOR").is_some_and(|v| !v.is_empty());
        Ui {
            quiet,
            color: !no_color && std::io::stdout().is_terminal(),
        }
    }

    #[cfg(test)]
    pub fn silent() -> Ui {
        Ui {
            quiet: true,
            color: false,
        }
    }

    pub fn status(&self, verb: &str, color: Color, message: &str) {
        // Errors are never quiet.
        let is_error = matches!(color, Color::Red) && verb == "error";
        if self.quiet && !is_error {
            return;
        }
        let padded = format!("{verb:>12}");
        let verb = if self.color {
            let code = match color {
                Color::Red => "1;31",
                Color::Green => "1;32",
                Color::Yellow => "1;33",
                Color::Blue => "1;34",
            };
            format!("\x1b[{code}m{padded}\x1b[0m")
        } else {
            padded
        };
        if is_error {
            eprintln!("{verb}  {message}");
        } else {
            println!("{verb}  {message}");
        }
    }
}
