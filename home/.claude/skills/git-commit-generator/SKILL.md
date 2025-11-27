---
name: git-commit-generator
description: "Generates git commit messages with emoji prefixes from staged changes. Analyzes diffs and selects appropriate emoji shortcodes to categorize commits. Use when committing changes to create consistent, descriptive commit history with visual categorization."
---

# Git Commit Message Generator

Generate concise git commit messages with emoji prefixes that categorize the type of change.

## When to Use This Skill

- You have staged changes and need a descriptive commit message
- You want consistent emoji-prefixed commit formatting
- You need to quickly categorize changes visually in git history

## Instructions

When asked to generate a commit message:

1. **Validate the diff first** using the helper script to check size and filter binary files:
   ```bash
   ~/.claude/skills/git-commit-generator/scripts/check-diff.sh --staged
   ```

   This script will:
   - Skip binary files (images, fonts, archives, etc.)
   - Warn about files exceeding 200 lines of diff
   - Fail if total diff exceeds 500 lines
   - Output only text file diffs suitable for analysis

   Options:
   - `--staged` - Check staged changes (default)
   - `--unstaged` - Check unstaged changes
   - `--max-lines=N` - Set max total lines (default: 500)
   - `--max-file-lines=N` - Set max per-file lines (default: 200)
   - `--summary` - Show only the summary without diff output
   - `--quiet` - Output only the filtered diff

   If the diff is too large, suggest the user commit in smaller chunks.

2. **Examine the changes** using the filtered output or `git diff --cached` (staged) to understand what changed

3. **Select the appropriate emoji** from this lookup table based on the primary change type:

| Emoji | Shortcode | Use For |
|-------|-----------|---------|
| :arrow_down: | `:arrow_down:` | Dependency downgrade |
| :arrow_up: | `:arrow_up:` | Dependency upgrade |
| :art: | `:art:` | UI improvements |
| :boom: | `:boom:` | Crash fix |
| :bug: | `:bug:` | Bug fix |
| :construction: | `:construction:` | Work in progress (do not merge) |
| :crossed_flags: | `:crossed_flags:` | Feature flag or A/B test addition |
| :fire: | `:fire:` | Code/file removal |
| :gem: | `:gem:` | Release/version bump |
| :green_heart: | `:green_heart:` | CI build fix |
| :lock: | `:lock:` | Update packages/dependencies (requirements.txt, uv.lock, *.lock) |
| :loud_sound: | `:loud_sound:` | Add logging |
| :mute: | `:mute:` | Remove logging |
| :non-potable_water: | `:non-potable_water:` | Memory leak fix |
| :package: | `:package:` | Code refactoring |
| :pencil: | `:pencil:` | Default fallback if nothing else fits |
| :racehorse: | `:racehorse:` | Performance improvement |
| :rocket: | `:rocket:` | Developer tools update |
| :satellite: | `:satellite:` | Add instrumentation/metrics |
| :shirt: | `:shirt:` | Linter fix |
| :sparkles: | `:sparkles:` | New feature |
| :tada: | `:tada:` | Initial commit |
| :wheelchair: | `:wheelchair:` | Accessibility update |
| :white_check_mark: | `:white_check_mark:` | Add tests |
| :wrench: | `:wrench:` | Config update |
| :zap: | `:zap:` | Breaking change |

4. **Write the commit message** following this format:
   ```
   :emoji_shortcode: Commit message here
   ```

5. **Follow these guidelines:**
   - Maximum 60 characters for the message (excluding emoji)
   - Use imperative mood ("Add feature" not "Added feature")
   - Be specific and descriptive
   - Return only one line with no extra text

6. **Prioritize change types** in this order when multiple apply:
   - docs - Documentation only changes
   - style - Changes that do not affect the meaning of the code
   - refactor - A code change that neither fixes a bug nor adds a feature
   - perf - A code change that improves performance
   - test - Adding missing tests or correcting existing tests
   - build - Changes that affect the build system or external dependencies
   - ci - Changes to CI configuration files and scripts
   - chore - Other changes that don't modify src or test files
   - revert - Reverts a previous commit
   - feat - A new feature
   - fix - A bug fix

## Output Format

```
:emoji_shortcode: Commit message
```

## Examples

```
:sparkles: Add user authentication endpoint
:bug: Fix null pointer in payment processor
:wrench: Update ESLint configuration rules
:arrow_up: Upgrade Django from 4.2 to 5.0
:fire: Remove deprecated API endpoints
:package: Extract validation logic to utils module
:white_check_mark: Add unit tests for user service
:lock: Update uv.lock with latest dependencies
:rocket: Add pre-commit hooks for linting
:art: Improve dashboard layout responsiveness
```
