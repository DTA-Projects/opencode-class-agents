# Setup

Put the files in this repo into opencode's **global config directory** (`~/.config/opencode`) so every opencode session, on every machine, picks them up automatically — agents, commands, and the Canvas helper.

## 1. Install prerequisites

- [opencode](https://opencode.ai/docs/installation/)
- Node.js 18+ (the Canvas helper uses `fetch`, no dependencies)
- git (any platform), plus `gh` if you want to create the remote repos below

## 2. Clone the config into place

The global config directory must already be set up by opencode. Clone this repo (or your own fork) straight into it:

Windows:
```
git clone https://github.com/<your-user>/opencode-class-agents "%USERPROFILE%\.config\opencode"
```

macOS / Linux:
```
git clone https://github.com/<your-user>/opencode-class-agents "$HOME/.config/opencode"
```

> The target directory must be empty. Do not clone into a nested `opencode/` folder.

## 3. Add your Canvas credentials

Copy the template and fill it in:

Windows:
```
copy "%USERPROFILE%\.config\opencode\canvas\.env.example" "%USERPROFILE%\.config\opencode\canvas\.env"
```

macOS / Linux:
```
cp "$HOME/.config/opencode/canvas/.env.example" "$HOME/.config/opencode/canvas/.env"
```

Edit `canvas/.env` with your values. Follow the instructions in `canvas/.env.example` (or see [docs/credentials.md](credentials.md)). The short version:

- `CANVAS_API_BASE` — your school's Canvas origin, e.g. `https://school.instructure.com`
- `CANVAS_COOKIE` — a full session cookie copied from your browser (tokens are often disabled by schools; the cookie always works)

Verify it:
```
cd %USERPROFILE%\.config\opencode\canvas
node canvas.mjs whoami
```

You should see `Authenticated as <your name>`.

## 4. Register your classes

```
node canvas.mjs courses
```

That prints each course's id, code, and name. For each class you want an agent for:

1. Copy `agents/template.md` to `agents/<course>.md`.
2. Fill in the `description` (when should opencode pick this agent?), `## What you do`, and its textbook path.
3. Replace `<COURSE_ID>` in the Canvas commands with the id from `courses`.

Test it: restart opencode and ask `what's due this week?` — the agent should call the helper and answer from your real course.

## 5. Point references at your textbooks

`opencode.jsonc` declares a `textbooks` reference at `~/Documents/++Textbooks`. Drop your textbook PDFs in that folder (any path works — just update `opencode.jsonc` and the agent files). If a file is over GitHub's 100 MB limit it can't be committed; copy it to each machine with Syncthing/USB/cloud instead, and keep the config referencing the path only.

## 6. Make the config sync across machines (recommended)

This repo is intentionally **public and pristine** — a template. Your real config (with course ids, creeds, and your school URL) should live in a **private** repo you clone to every machine:

1. Create an empty private repo, e.g. `opencode-config`.
2. `git remote set-url origin <your-private-repo-url>` in `~/.config/opencode`.
3. Commit your real `.env.example`-derived `.env`, agents with real course ids, and notes repo. Then `git push`.

Wait — never push `.env` (it's gitignored). See [Security](#security).

The `/sync` command runs `git-sync.ps1`, which does a safe `pull --rebase --autostash`, commits, and pushes TWO repos: the config and (optionally) a second repo of per-class notes at `~/Documents/Study Materials`. It uses `$HOME`-relative paths, so one script works on every machine no matter the username.

- `/sync` — pull then push (safe default)
- `/sync push` — commit + push only
- `/sync pull` — fetch + rebase only
- `/sync-here` — same thing, but for whatever git repo you're currently working in

Run `/sync` at the start and end of any editing session. Only edit on one machine at a time — simultaneous pushes from two machines can conflict (the script will tell you, and you resolve manually).

## Security

- **NEVER commit `canvas/.env`** — it is a live session credential. It is gitignored in this repo; keep the ignore in your private repo too.
- A Canvas session cookie expires when your browser login does (days/weeks). When `node canvas.mjs` starts failing with auth errors, copy a fresh one.
- Do NOT point an always-on sync tool (Syncthing, OneDrive, Dropbox) at `~/.config/opencode` — it's a git checkout and can be corrupted.
- Do NOT sync `~/.local/share/opencode` or `~/.local/state/opencode` between machines — machine-private sessions, history, and auth.
- opencode loads config at startup — after editing agents, commands, or `opencode.jsonc`, restart opencode before testing.