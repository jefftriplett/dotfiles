# CLAUDE.md - Dotfiles Developer Guide

## Build Commands
- Format all justfiles: `just fmt`
- Lint (prek runs `.pre-commit-config.yaml`; CI runs the same): `just lint`
- Regenerate the recipe list in the manual: `just update-docs`
- Preview the manual: `just docs-serve` (Zensical, config in `zensical.toml`, pages in `docs/`)

## Python Setup
- Install Python tools: `just python::bootstrap`
- Install specific Python packages: `just python::uv-pip-install PACKAGE`
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
- Package management: Homebrew, uv
- Automation: Just (command runner), homesick (dotfiles)
