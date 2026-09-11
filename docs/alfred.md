# Alfred

[Alfred][alfred] with the [Powerpack][alfred-powerpack] is the launcher on every Mac.
Hammerspoon owns windows and hotkeys; Alfred handles everything typed: apps, files,
snippets, and the workflows below. The app comes from the `alfred` cask in every Brewfile
and updates itself.

## Preferences

Alfred keeps its preferences in `~/Library/Application Support/Alfred/Alfred.alfredpreferences`
on each Mac. That folder is **not** synced and is not in the dotfiles, so each Mac has its own
workflows, versions, and settings. The Dracula theme is imported by hand on each Mac; see
[Theme](index.md#theme).

Two folders under iCloud Drive, `Alfred/` and `Alfred Preferences/`, hold preference bundles
from 2017. They are leftovers from an older sync setup and nothing reads them.

## Workflows

| Workflow | Author | Keyword | Installed on |
| -------- | ------ | ------- | ------------ |
| [Emoji Search][emoji-search] | Jeff Triplett | `emoji` | all |
| [Sublime Text Projects][sublime-projects] | Dean Jackson | `.st` | all |
| [Backup Preferences][backup-preferences] | Alfred Team | `start backups`, `restore backups` | studio |
| Alfred Justfile | local | `just` | studio |

Emoji Search is built from `~/Projects/alfred-workflow/alfred-emoji-search-git`, a
Syncthing-mirrored project, and installed by hand on each Mac. The three Macs do not
have to run the same version of a workflow, and today they do not.

Alfred Justfile is an unfinished local workflow that lists `just` recipes through a script
filter. Its script path still points at a pyenv shim, and pyenv is gone, so the keyword
does nothing until the path is changed to `/opt/homebrew/bin/uv`.

## Backups

The Backup Preferences workflow on the studio makes a daily archive of the whole
preferences folder. It is configured in the workflow's own settings, not in a file here:

| Setting | Value |
| ------- | ----- |
| Target | `~/Library/Mobile Documents/com~apple~CloudDocs/Backups` |
| Time | 18:00 daily, through a launchd agent named `com.alfredapp.vitor.backuppreferences` |
| Versions kept | 8 |

`start backups` makes one now. `restore backups` lists the archives, restores one, and
restarts Alfred. The archive is a `.tgz` of the preferences folder, so it also serves as a
way to copy the studio's workflows to another Mac: restore it there, then remove the
workflows that do not belong.

Only the studio backs up today. To cover the other two Macs, install the workflow there
from the [Alfred Gallery][backup-preferences] and point it at the same iCloud folder;
the file names carry the hostname, so the archives do not collide.

[alfred]: https://www.alfredapp.com/
[alfred-powerpack]: https://www.alfredapp.com/powerpack/
[backup-preferences]: https://alfred.app/workflows/alfredapp/backup-preferences/
[emoji-search]: https://github.com/jefftriplett/alfred-emoji-search
[sublime-projects]: https://github.com/deanishe/alfred-sublime-text
