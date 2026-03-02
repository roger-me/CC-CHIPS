# Usage Row Design

Add a second row displaying 5-hour rolling usage and weekly usage from the Anthropic OAuth usage API.

## Layout

```
Row 1:  [ folder + path ]  [ git branch ]  [ model + context + clock ]
Row 2:  Current: ●●●○○○○○○○○○○○○○○○○○  16% used | Resets: 14:00, Monday, 02/03/2026
        Weekly:  ●●●●●●○○○○○○○○○○○○○○  34% used | Resets: 9:00, Friday, 06/03/2026
```

- Row 2 is plain white text (no chips, no themed backgrounds)
- Bar uses 20-dot `●`/`○` with color shifting by percentage
- If no OAuth token or API fails, Row 2 is silently omitted

## Data Source

OAuth usage API: `GET https://api.anthropic.com/api/oauth/usage`

Headers:
- `Authorization: Bearer <oauth_token>`
- `anthropic-beta: oauth-2025-04-20`

Response fields used:
- `.five_hour.utilization` (0-100)
- `.five_hour.resets_at` (ISO 8601)
- `.seven_day.utilization` (0-100)
- `.seven_day.resets_at` (ISO 8601)

## OAuth Token Resolution

1. `$CLAUDE_CODE_OAUTH_TOKEN` env var
2. macOS Keychain: `security find-generic-password -s "Claude Code-credentials" -w`
3. `~/.claude/.credentials.json` file
4. GNOME Keyring via `secret-tool`

Requires `user:profile` scope. Re-authenticate with `claude logout && claude login` if missing.

## Caching

- Cache file: `/tmp/claude/statusline-usage-cache.json`
- Max age: 30 seconds
- Falls back to stale cache if API call fails

## Bar Colors (dynamic)

- Green: < 50%
- Orange: 50-69%
- Yellow: 70-89%
- Red: >= 90%
