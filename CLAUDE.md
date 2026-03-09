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

- **Chip 1** (left): Folder icon + project folder name
- **Chip 2** (middle, git only): GitHub icon + branch icon + branch name + dirty indicator
- **Chip 3** (right): Space invader + model name + window icon + context bar % + clock icon + time

Row 2 (usage, only renders if OAuth token with `user:profile` scope is available):
- **Current**: Hourglass + 20-dot bar + pct + reset datetime
- **Weekly**: Calendar + 20-dot bar + pct + reset datetime
- Bar color shifts green > orange > yellow > red as usage increases

### Dependencies

- A **Nerd Font** (e.g. JetBrains Mono Nerd Font) must be set as the terminal font
- `jq` for JSON parsing
- `git` for branch/dirty detection
- `curl` for usage API calls (Row 2)
- OAuth credentials (macOS Keychain, env var, or creds file) for usage API

### Icon Codepoints (Nerd Font)

| Icon | Codepoint | Name |
|------|-----------|------|
| Folder | U+F07C | fa-folder-open |
| GitHub | U+F09B | fa-github |
| Branch | U+E725 | dev-git_branch |
| Model | U+F0BC9 | nf-md-space_invaders |
| Context | U+F2D0 | fa-window_maximize |
| Clock | U+F017 | fa-clock |
| Hourglass | U+F253 | fa-hourglass-half |
| Calendar | U+F073 | fa-calendar |

## Usage Row

Row 2 displays your plan usage limits by calling the Anthropic OAuth usage API. It requires an OAuth token with the `user:profile` scope.

If Row 2 doesn't appear, re-authenticate to get the required scope:

```
claude logout && claude login
```

The usage data is cached for 30 seconds. If no valid token is found or the API call fails, Row 2 is silently omitted.

## Creating a New Theme

1. Copy an existing theme: `cp themes/cool.sh themes/mytheme.sh`
2. Edit the 9 color variables to your palette
3. Set `export CC_CHIPS_THEME=mytheme`
