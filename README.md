# opencode-class-agents

Turn any Canvas (LMS) course into a personal AI study agent.

This repository is a working, documented example of how I use [opencode](https://opencode.ai) for school:

- a **zero-dependency Node script** that talks to your school's [Canvas API](https://canvas.instructure.com/doc/api/) and turns pages, modules, assignments, and files into plain text an AI agent can read
- **per-class tutor agents** that know your syllabus, due dates, and textbook — activated by simply asking
- an **opencode config** that wires it all together with `references`, `instructions`, and custom `/` commands
- a **git-based sync workflow** so the whole setup (and your notes) lives on every machine you own

Everything here is generic — copy it, change your school's URL and your textbooks, and you're done. No personal data, no secrets, no API keys are included (see [Security](#security)).

---

## Install in one command

On a clean machine ([git](https://git-scm.com/downloads) + [Node.js 18+](https://nodejs.org/en/download) present) the installer: backs up any existing config, clones this template into `~/.config/opencode`, re-inits it as **your own fresh git repo** (not tied to this template), scaffolds `canvas/.env` + `CONTEXT.md`, optionally installs opencode itself, and prints your next steps.

**Windows (PowerShell):**

```powershell
powershell -ExecutionPolicy Bypass -Command "irm https://raw.githubusercontent.com/DTA-Projects/opencode-class-agents/main/install.ps1 | iex"
```

**macOS / Linux:**

```bash
curl -fsSL https://raw.githubusercontent.com/DTA-Projects/opencode-class-agents/main/install.sh | bash
```

For scripted / no-prompt installs: `$env:SKIP_PROMPTS="1"` (Windows) or `SKIP_PROMPTS=1 CONFIG_DIR=/path` (Unix). Details in [docs/SETUP.md](docs/SETUP.md).

**Prerequisite installers** (if you don't have them yet):

- [Install git](https://git-scm.com/downloads) (Windows/macOS/Linux)
- [Install Node.js 18+](https://nodejs.org/en/download) (the Canvas helper needs Node)
- [Install opencode](https://opencode.ai/docs/installation/) (also offered by the installers below)

---

## How it works

```
┌────────────────────────────┐      ┌──────────────────────────────────────┐
│         You ask            │      │        opencode (CLI + AI)           │
│  "when is the calc midterm?"│      │                                      │
└─────────────┬──────────────┘      │  agent/calculus.md  (which agent)    │
              │                      │  ┌────────────────────────────────┐  │
              ▼                      │  │ The agent knows:              │  │
┌────────────────────────────┐      │  │  • its job (tutor a course)    │  │
│ opencode global config     │──────│  │  • its textbook (reference)    │  │
│ ~/.config/opencode         │      │  │  • its Canvas course id        │  │
└────────────────────────────┘      │  │  • how to call canvas.mjs      │  │
              │                      │  └──────────────┬─────────────────┘  │
              ▼                      │                 │                    │
┌────────────────────────────┐      │                 ▼                    │
│  canvas/canvas.mjs         │      │       node canvas.mjs assignments    │
│  (tiny Node API client)    │──────│                 │                    │
└────────────────────────────┘      │                 ▼                    │
              │                      │  "Midterm: Oct 12, 100 pts, ch 1-4"  │
              ▼                      └──────────────────────────────────────┘
┌────────────────────────────┐
│  your school's Canvas API  │
│  https://<school>.instructure.com
└────────────────────────────┘
```

1. `canvas.mjs` authenticates once via a `.env` file (session cookie or API token) and fetches your courses, syllabus pages, modules, assignments, and files.
2. Each course gets an **agent file** (`agent/calculus.md`, `agent/system-administration.md`, ...) — a small markdown file with frontmatter that tells opencode when to use it, what it is, and how to touch your course.
3. Because the helper turns messy Canvas HTML into readable text, the agent can answer real questions: *"what's due this week?", "explain the derivative rules from chapter 3?"* — grounded in *your* actual course content and *your* textbook.

## What's in the box

| Path | What it is |
|---|---|
| `canvas/canvas.mjs` | Canvas API helper. No dependencies, plain Node `fetch`. Commands: list courses, pages, modules, assignments, files, download files. |
| `canvas/.env.example` | Template for your credentials. Copy to `.env` and fill in. Never commit `.env`. |
| `agents/*.md` | Example per-course tutor agents (with a blank `agents/template.md` to copy). |
| `commands/sync.md`, `commands/sync-here.md` | Custom opencode `/sync` commands that run the PowerShell scripts below. |
| `git-sync.ps1`, `git-sync-here.ps1` | One-command pull/push scripts for keeping config (and any repo) synced across machines. |
| `install.ps1`, `install.sh` | One-command installers for a clean machine (Windows / Unix). See [Install in one command](#install-in-one-command). |
| `opencode.jsonc` | Global opencode config: points at the `references` (textbooks) and loads `CONTEXT.md` as instructions. |
| `CONTEXT.example.md` | Optional auto-loaded "session context" file — the rules the agent should always remember. |
| `docs/SETUP.md` | Step-by-step install guide for a new machine. |

## Manual quick start

> Prefer to run the one-command installer above instead? Skip straight to step 4.

**Prereqs:** [opencode](https://opencode.ai/docs/), [Node.js 18+](https://nodejs.org/en/download), [git](https://git-scm.com/downloads).

```bash
# 1. Put these files into opencode's global config directory
git clone https://github.com/<your-user>/opencode-class-agents ~/.config/opencode
#    (or fork this repo and clone your fork - recommended so you keep the template git.)

# 2. Create the auto-loaded session context
cp ~/.config/opencode/CONTEXT.example.md ~/.config/opencode/CONTEXT.md

# 3. Set up Canvas credentials (see docs/credentials)
cd ~/.config/opencode/canvas
copy .env.example .env      # then fill in CANVAS_API_BASE + cookie/token

# 4. Verify the connection
node canvas.mjs whoami

# 4. Register your courses in an agent file
node canvas.mjs courses     # copy the course id into agents/<course>.md
```

Then just start opencode and ask a question: `explain the homework due this week` or `what does the syllabus say about late submissions?`

The full walkthrough — including textbook references, creating your agents, and the multi-machine sync — is in [docs/SETUP.md](docs/SETUP.md).

## Canvas helper

```bash
node canvas.mjs courses                     # your active courses (id, code, name)
node canvas.mjs frontpage <courseId>        # the course home page
node canvas.mjs modules <courseId>          # module list
node canvas.mjs page <courseId> <pageUrl>   # one wiki page as readable text
node canvas.mjs assignments <courseId>      # assignments + due dates
node canvas.mjs files <courseId>            # course file listing
node canvas.mjs download <courseId> <fileId># download a file (e.g. lecture PDFs)
node canvas.mjs whoami                      # verify your credentials
```

It handles pagination (the `Link` header), strips HTML to readable text, and gives clear errors when your cookie has expired — the most common failure.

## Writing your own class agent

Each agent is just a markdown file in `agents/` with YAML frontmatter:

```markdown
---
description: Calculus I tutor. Use for limits, derivatives, and integrals.
mode: primary
---

You are the user's Calculus I tutor.

## Textbook
Your reference text is at `~/Documents/++Textbooks/Calculus.pdf`.
Never read the whole PDF — Grep or Read only the relevant section.

## What you do
Explain concepts step by step, show worked solutions, and reference the
textbook chapter that covers the topic.

## Canvas access
Canvas course: 12345.
Run `node canvas.mjs assignments 12345` (from the canvas folder) to see
due dates and the syllabus.
```

The `description` decides when opencode picks this agent. The `~/` paths resolve against whichever machine you're on, which is what makes the config portable.

## Multi-machine sync

I keep this config in a private git repo cloned to every machine at `~/.config/opencode`. The `/sync` command (via `git-sync.ps1`) does a safe `pull --rebase --autostash`, commits, and pushes — for this config and a second repo of per-class notes. `/sync-here` does the same for *any* repo you happen to be working in. Tips in `docs/SETUP.md`.

## Security

- **Never commit `.env`** — it holds a live Canvas session cookie or API token. It's gitignored here on purpose.
- A session cookie expires with your login; when commands start failing, re-copy a fresh one.
- Don't point an always-on sync tool (Syncthing/OneDrive) at a git checkout of your config.
- Before publishing a template like this one, scrub course ids, school URLs, and any personal info — this repo has none, keep it that way if you fork it.

## How this was built

Built iteratively with opencode over a few evenings:

1. Write a first draft `canvas.mjs`, then run `node canvas.mjs courses` against the live API and let the agent fix whatever errors came back (the HTML-to-text stripping, the pagination, and the cookie-expiry hints all came out of real failures).
2. Register one course at a time — `courses` prints the id, the id goes into an agent file, ask a question, tighten the prompt.
3. Add the sync workflow once edit fatigue from switching machines hit — mirrors and scheduled tasks were rejected in favor of the explicit `/sync` command, documented in the notes.

## License

MIT — see [LICENSE](LICENSE).