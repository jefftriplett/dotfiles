# CLAUDE.md - Dotfiles Developer Guide

## Build Commands
- Format justfile: `just --fmt --unstable`
- Update Brewfile: `just _update-brewfile`
- Update README docs: `just _update-readme-docs`

## Python Setup
- Install Python tools: `just _python-bootstrap`
- Install specific Python packages: `just pip-install PACKAGE`
- Linting tools: pyright, ruff-lsp

## Code Style Guidelines
- PEP8 compatible (ignores: E501, F0401, R0201, R0903)
- Line length: adhere to rulers at 72, 79, and 119 characters
- Indentation: 4 spaces (no tabs)
- Always ensure newline at EOF
- Trim trailing whitespace

## Git Conventions
- Use emoji shortcodes in commit messages from the established list
- Commit messages should be 50 characters or less (excluding emoji)
- Format: `{emoji_short_code} {commit_message}`

## Tools Used
- Package management: Homebrew, uv, pyenv
- Automation: Just (command runner), homesick (dotfiles)
