---
description: Sync the current working directory's git repo to GitHub. Usage: /sync-here [push|pull|both] [commit message]
agent: build
---

Sync the CURRENT working repository (wherever opencode is currently open), using the same pull/commit/push behavior as `/sync` but on a single repo instead of the two fixed ones. Run this exact command with the Bash tool (it acts on the current working directory, so no paths are needed):

powershell -NoProfile -ExecutionPolicy Bypass -File "$HOME/.config/opencode/git-sync-here.ps1" -Mode <MODE> -Message "<MSG>"

Decide <MODE> and <MSG> as follows:

- <MODE> is the first word of the user's text after /sync-here if it is `push`, `pull`, or `both`; otherwise default to `both`.
  - `push` = commit local changes and push (use if you do not want to touch remote state)
  - `pull` = fetch and rebase onto the latest remote content (safe on a machine you have not touched in a while)
  - `both` = pull then push, so the local machine is up to date before sending your changes. This is the safe default and what you should pick when the user just says `/sync-here`.
- <MSG> is the remaining text after the mode word. Wrap it in double quotes. If empty, use "Sync from opencode".
- The script only touches the current working repository. Unlike `/sync`, it does NOT touch `~/.config/opencode` or `~/Documents/Study Materials`. If the current directory is not a git repo it skips it and exits.
- If the script reports a failed pull (conflict) or failed push, STOP and report the exact error to the user. Do not retry, do not force-push, do not modify the script. A pull failure means a merge conflict someone else created first — the user must resolve it.