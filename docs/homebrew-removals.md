
### iTerm2

- `iterm2` cask removed on all three Macs. Ghostty and cmux are the terminals.
- Repo: the iTerm2 shell block in `50-osx.bash`, the `~/.config/iterm2` link
  in `mise.toml` and `.gitignore`, and the cask in `Brewfile` and
  `Brewfile.cog` are gone. The `~/.config/iterm2` symlink and the castle
  folder behind it, which held only app state, were deleted on each Mac.
