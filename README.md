![CC CHIPS Cover](https://github.com/roger-me/CC-CHIPS/releases/download/v1.0.0/CC.CHIPS.COVER.png)

# CC CHIPS

Chip-style status line themes for Claude Code with Powerline pills, Nerd Font icons, and real-time session info.

## Themes

| Theme | Colors |
|-------|--------|
| **Claude** | Terracotta and white |
| **Cool** | Blue and orange |
| **Retro** | Retro pink and lime |
| **Cyber** | Teal, yellow, and crimson |

## Features

- Powerline pill-shaped chips with rounded edges
- Git branch and dirty state detection
- Model name with context window usage bar
- Session cost tracking
- Easy theme switching without restarting Claude Code

## Requirements

- A [Nerd Font](https://www.nerdfonts.com/) as your terminal font (e.g. JetBrains Mono Nerd Font)
- [`jq`](https://jqlang.github.io/jq/) installed
- `git` (for branch detection)

## Installation

1. Copy `engine.sh` and your chosen theme to `~/.claude/`:

```bash
cp engine.sh ~/.claude/engine.sh
cp themes/claude.sh ~/.claude/statusline.sh
```

2. Make them executable:

```bash
chmod +x ~/.claude/engine.sh ~/.claude/statusline.sh
```

3. Add to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/statusline.sh"
  }
}
```

4. Restart Claude Code.

## Switching Themes

Replace the theme file — the engine stays the same:

```bash
cp themes/cyber.sh ~/.claude/statusline.sh
```

No restart needed.

## Creating a Custom Theme

1. Copy an existing theme:

```bash
cp themes/cool.sh themes/mytheme.sh
```

2. Edit the 9 color variables (`FG_LEFT`, `BG_LEFT`, `FG_LEFT_TEXT`, etc.) to your palette. Each theme is ~20 lines -- the shared rendering logic lives in `engine.sh`.
