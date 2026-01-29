# CC CHIPS

Chip-style status line themes for Claude Code using Nerd Font icons and Powerline pill edges.

## Project Structure

```
engine.sh        # Shared rendering logic (sourced by themes)
themes/          # Each .sh file defines colors and sources engine.sh
  claude.sh      # Terracotta (#C6613F) / white palette
  cool.sh        # Blue (#008BB7) / orange (#FF4D00) palette
  retro.sh       # Pink (#C41665) / lime (#9CC02A) palette
  cyber.sh       # Yellow (#FFF700) / teal (#132831) / crimson (#46151F) palette
```

## How Themes Work

Each theme file defines 9 color variables for 3 chips, then sources `engine.sh` which handles everything else:
1. Reads JSON from stdin (Claude Code passes status data)
2. Extracts: project path, git branch/dirty state, model name, context window usage, cost
3. Renders 3 pill-shaped chips using Powerline glyphs and Nerd Font icons

### Theme Color Variables

Each theme defines these 9 variables:
- `FG_LEFT`, `BG_LEFT`, `FG_LEFT_TEXT` — Chip 1 (folder + path)
- `FG_MID`, `BG_MID`, `FG_MID_TEXT` — Chip 2 (git info)
- `FG_RIGHT`, `BG_RIGHT`, `FG_RIGHT_TEXT` — Chip 3 (model + context + cost)

### Chip Layout

- **Chip 1** (left): Folder icon + project path
- **Chip 2** (middle, git only): GitHub icon + branch icon + branch name + dirty indicator
- **Chip 3** (right): Space invader + model name + window icon + context bar % + coins icon + cost

### Dependencies

- A **Nerd Font** (e.g. JetBrains Mono Nerd Font) must be set as the terminal font
- `jq` for JSON parsing
- `git` for branch/dirty detection

### Icon Codepoints (Nerd Font)

| Icon | Codepoint | Name |
|------|-----------|------|
| Folder | U+F07C | fa-folder-open |
| GitHub | U+F09B | fa-github |
| Branch | U+E725 | dev-git_branch |
| Model | U+F0BC9 | nf-md-space_invaders |
| Context | U+F2D0 | fa-window_maximize |
| Cost | U+EDE8 | fa-coins |

## Creating a New Theme

1. Copy an existing theme: `cp themes/cool.sh themes/mytheme.sh`
2. Edit the 9 color variables to your palette
3. The `source "$SCRIPT_DIR/../engine.sh"` line at the bottom handles all rendering

## Installation

Copy or symlink a theme to your Claude Code status line config:

```bash
cp themes/cool.sh ~/.claude/statusline.sh
```

Then set it in your Claude Code settings as the status line script.
