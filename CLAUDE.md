# CC CHIPS

Chip-style status line themes for Claude Code using Nerd Font icons and Powerline pill edges.

## Project Structure

```
engine.sh        # Entry point — loads theme and renders status line
themes/          # Color-only theme definitions
  claude.sh      # Terracotta (#C6613F) / white palette
  cool.sh        # Blue (#008BB7) / orange (#FF4D00) palette
  retro.sh       # Pink (#C41665) / lime (#9CC02A) palette
  cyber.sh       # Yellow (#FFF700) / teal (#132831) / crimson (#46151F) palette
```

## How It Works

`engine.sh` is the entry point. It reads the `CC_CHIPS_THEME` env var (defaults to `claude`), sources the matching theme file from `themes/`, then renders the status line.

Each theme file defines 9 color variables:
- `FG_LEFT`, `BG_LEFT`, `FG_LEFT_TEXT` — Chip 1 (folder + path)
- `FG_MID`, `BG_MID`, `FG_MID_TEXT` — Chip 2 (git info)
- `FG_RIGHT`, `BG_RIGHT`, `FG_RIGHT_TEXT` — Chip 3 (model + context + cost)

### Chip Layout

- **Chip 1** (left): Folder icon + project path
- **Chip 2** (middle, git only): GitHub icon + branch icon + branch name + dirty indicator
- **Chip 3** (right): Space invader + model name + window icon + context bar % + arrow up icon + input tokens + arrow down icon + output tokens + coins icon + cost

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
| Tokens In | U+F062 | fa-arrow_up |
| Tokens Out | U+F063 | fa-arrow_down |

## Creating a New Theme

1. Copy an existing theme: `cp themes/cool.sh themes/mytheme.sh`
2. Edit the 9 color variables to your palette
3. Set `export CC_CHIPS_THEME=mytheme`
