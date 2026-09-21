---
description: Sync your config and study materials to GitHub. Usage: /sync [push|pull|both] [commit message]
agent: build
---

Sync the user's two git repos using the sync script. Run this exact command with the Bash tool (it expands $HOME to the current user's home directory, so it works on any machine):

powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/git-sync.ps1" -Mode <MODE> -Message "<MSG>"

Decide <MODE> and <MSG> as follows:

- <MODE> is the first word of the user's text after /sync if it is `push`, `pull`, or `both`; otherwise default to `both`.
  - `push` = commit local changes and push (use if you do not want to touch remote state)
  - `pull` = fetch and rebase onto the latest remote content (safe on a machine you have not touched in a while)
  - `both` = pull then push, so the local machine is up to date before sending your changes. This is the safe default and what you should pick when the user just says `/sync`.
- <MSG> is the remaining text after the mode word. Wrap it in double quotes. If empty, use "Sync from opencode".
- The script covers both repos automatically (`~/.config/opencode` and `~/Documents/Study Materials`). Do not run separate git commands.

If the script reports a failed pull (conflict) or failed push, STOP and report the exact error to the user. Do not retry, do not force-push, do not modify the script. A pull failure means a merge conflict another machine created first — the user must resolve it.