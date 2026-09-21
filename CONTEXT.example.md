# Runtime context (auto-loaded into every opencode session)

Copy this file to `CONTEXT.md` in your config directory — opencode loads it
into every session via the `instructions` field in `opencode.jsonc`. It is the
"always-on" reminder of how your setup is wired. Edit the headings below to
match your own setup; keep it short, it is loaded every single time.

## Repos

- **opencode-config** — this directory (`~/.config/opencode`): agents, commands, sync scripts, and the Canvas helper. Clone it to every machine you use.
- **study-materials** — `~/Documents/Study Materials`: per-class notes and cheat sheets.

## Syncing between machines

- Use the `/sync` command: `/sync` (pull then push), `/sync push`, `/sync pull`. It runs `git-sync.ps1`, which operates on BOTH repos at once.
- Use `/sync-here` for the CURRENT working repo (same push/pull/both modes) — it runs `git-sync-here.ps1` on `$PWD` and never touches the config or study repos.
- Do not run bare git add/commit/push/pull for these repos unless debugging — use the script.
- Sync is manual. Run `/sync` at the start and end of any session where files were edited.

## Key locations

- Textbooks: `~/Documents/++Textbooks` — NOT tracked in git (too large; copy them per machine).
- Study materials: `~/Documents/Study Materials`.
- Canvas helper: `~/.config/opencode/canvas/canvas.mjs`. Run it from the canvas directory: `cd ~/.config/opencode/canvas`, then `node canvas.mjs <command>`.

## Hard rules

1. NEVER commit or share `canvas/.env` — it holds your Canvas API token / session cookie.
2. NEVER point a mirror/sync tool (Syncthing, OneDrive, etc.) at `~/.config/opencode` — it is a git repo and can be corrupted.
3. NEVER sync `~/.local/share/opencode` or `~/.local/state/opencode` between machines — machine-private sessions, history, and auth.
4. After editing opencode config, agents, or commands, the user must restart opencode for changes to take effect (config is loaded at startup).