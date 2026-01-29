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
- Switch themes with an env var — no file copying or restart needed

## Requirements

- A [Nerd Font](https://www.nerdfonts.com/) as your terminal font (e.g. JetBrains Mono Nerd Font)
- [`jq`](https://jqlang.github.io/jq/) installed
- `git` (for branch detection)

## Installation

1. Clone the repo:

```bash
git clone https://github.com/roger-me/CC-CHIPS.git ~/.claude/cc-chips
```

2. Add to your Claude Code settings (`~/.claude/settings.json`):

```json
{
  "statusLine": {
    "type": "command",
    "command": "~/.claude/cc-chips/engine.sh"
  }
}
```

3. Restart Claude Code.

## Switching Themes

Set the `CC_CHIPS_THEME` env var in your shell config (`~/.zshrc` or `~/.bashrc`):

```bash
export CC_CHIPS_THEME=cyber
```

Available values: `claude` (default), `cool`, `retro`, `cyber`

## Creating a Custom Theme

1. Create a new file in the `themes/` directory:

```bash
cp themes/cool.sh themes/mytheme.sh
```

2. Edit the 9 color variables (`FG_LEFT`, `BG_LEFT`, `FG_LEFT_TEXT`, etc.) to your palette.

3. Set your theme:

```bash
export CC_CHIPS_THEME=mytheme
```
