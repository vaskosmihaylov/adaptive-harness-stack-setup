# adaptive-harness-stack-setup

One shared set of global guidelines for **Claude Code** and **Codex CLI**, sized to what current
models actually need — which is far less than what harnesses were built for a year ago.

Built for a Senior DevOps toolchain: Terraform, Kubernetes, Helm, Ansible, Puppet, Docker, CI.

## The premise

Anthropic's Opus 5 guide says to delete generic verification scaffolding, and OpenAI's GPT-5.6
guide reports better quality and materially lower token use from leaner system prompts:

> *"If your prompt contains explicit verification instructions... remove them: instructions like
> these cause over-verification on Claude Opus 5... The same applies to legacy harness scaffolding
> that adds separate verification steps."*

And Claude Code's best-practices page gives the test for every remaining line:

> *"Would removing this cause Claude to make mistakes?" If not, cut it. Bloated CLAUDE.md files
> cause Claude to ignore your actual instructions!*

So this repo is mostly an exercise in subtraction. What survived is: four documented Opus 5
behaviors that still need explicit tuning (verbosity, narration, scope creep, over-delegation),
a compact GPT-5.6 autonomy boundary, a documentation-freshness rule because infra tooling outruns
any training cutoff, and a DevOps blast-radius section that protects production.

`docs/SOURCES.md` justifies every kept rule and every cut one, with citations.

## When do I run what

| Situation | Do this | Where |
|---|---|---|
| New Claude or GPT model ships | `/adaptive-harness-stack-setup` → **retune** | anywhere |
| Agent is ignoring instructions, over-verifying, over-delegating | same — **retune** | anywhere |
| You edited `src/` or `agents/` by hand | `./install.sh` | this repo |
| New machine | clone, run `./install.sh`, then `./skills.sh` for the approved third-party tier | this repo |
| Starting work in a repo that has no `CLAUDE.md` | `/adaptive-harness-stack-setup` → **repo** | that repo |

Two things to be clear about:

- **`install.sh` is not per repo.** It writes global files only. Run it once per machine, and
  again whenever `src/` or `agents/` changes.
- **The skill is not `install.sh` with extra steps.** *retune* decides what the global files
  should say, then runs `install.sh` for you. *repo* writes that repository's own files and
  never touches the global ones. On a model release you want retune, not a bare re-install —
  re-installing unchanged sources changes nothing.

## Layout

```
src/          core.md + per-harness header/footer   ← edit these
dist/         generated CLAUDE.md and AGENTS.md     ← never edit; build.sh overwrites
settings/     Claude permission allowlist (read-only infra commands pre-approved)
templates/    per-repo CLAUDE.md / AGENTS.md starter
skill/        SKILL.md — re-run this setup when a new model ships
vendor/skills/ adapted third-party skills (blast-radius, correct); install.sh links them globally
skills.sh     provisions/verifies the global skill + plugin tier (manifest lives at its top)
docs/         SOURCES.md (rationale + citations), PER-REPO.md (the full repo assessment),
              SKILLS.md (the global skill/plugin layer), TOKENS.md (tiering)
backups/      machine-local timestamped copies of changed files (ignored by Git)
```

`src/core.md` is the single source of truth. Both output files are generated from it, so the two
harnesses can't drift apart.

## Install

```bash
./install.sh --dry-run     # show what changes
./install.sh               # install both
./install.sh --claude      # or one at a time
./install.sh --uninstall   # remove what it installed
```

It writes `~/.claude/CLAUDE.md`, `~/.codex/AGENTS.md`, merges a permission allowlist into
`~/.claude/settings.json` with `jq`, and symlinks the skill into both harnesses. It backs up
anything it replaces into `backups/`.

It installs instruction files, agents, and a permission allowlist — nothing else. No wrappers, no
shims, no shell-profile edits, no third-party binaries. Anything that would only work on one
machine's Homebrew prefix, network, or certificate layout is a documented note in `docs/`, not code
here: this checkout has to install cleanly on every Mac, personal or work, Intel or ARM.

It deliberately does **not** rewrite `~/.codex/config.toml` — that file holds ~50 project trust
levels. It reports drift from the recommended settings and leaves the fix to you.

Apart from the vendored copies in `vendor/skills/`, which it links like `skill/`, it does not
install third-party skills, plugins, or MCP servers — `./skills.sh` provisions the
global skill and plugin tier, because that needs the network and `install.sh` does not. `install.sh`
reports whether the tier is complete and points at `./skills.sh` when it isn't. Scope and approval
boundaries live in `docs/SKILLS.md`; MCP servers stay per repo (`docs/PER-REPO.md`).

Auth, history, logs, and session state are never touched.

The installer skips files that are already current, so routine re-runs do not create duplicate
backup snapshots. Backups stay local to the machine and are deliberately excluded from Git.

## Set up another machine

```bash
git clone <repository-url>
cd adaptive-harness-stack-setup
./validate.sh
./install.sh --dry-run
./install.sh
./skills.sh                # global skill and plugin tier (needs network)
./skills.sh --check        # confirm it landed
```

Read `docs/SKILLS.md` before running `./skills.sh` — everything it installs is third-party code
that runs with full agent permissions. Do not copy
`~/.claude` or `~/.codex` between machines: those directories also contain authentication,
history, caches, project trust, and session state that this repository intentionally does not
manage.

## Editing

Edit authored sources, run `./validate.sh`, then re-run `./install.sh`. Never edit `dist/`.

Adding a line? It has to pass the test: **would removing this cause a mistake the model wouldn't
otherwise make?** If the answer is no, the line makes the file worse, not better.

## Re-tuning when a new model ships

Run `/adaptive-harness-stack-setup` in either harness. It re-reads the current vendor prompting
guides, diffs them against `src/core.md`, and proposes keeps and cuts. Bias is toward cutting —
every release so far has needed less instruction than the one before.

Also re-run it when the agent starts ignoring instructions. That's usually the file having grown
back past the point where the rules that matter stay visible.

## Token usage

Two levers, covered in `docs/TOKENS.md`:

1. **Right-sizing** — the default is small. A question gets an answer, not a plan and a subagent.
   Escalate only the dimension that's actually short: unclear approach → plan, wide unknown
   surface → delegate, hard reasoning → raise effort. This is the bigger win and it's prompting,
   not config.
2. **Tiering** — planning and judgment stay on Opus/Sol; bulk work goes to read-only cheap
   utilities: the native exploration override (`Explore` on Haiku / `explorer` on Terra),
   `log-digger` (Haiku/Luna for CI, pod, and plan output), and the Claude-only `docs-lookup`.

Three agents at most, deliberately. `docs/TOKENS.md` lists what was considered and rejected, and the
test for adding another: *does it need a different model, a different tool set, or a separate
context window?* If not, it's a prompt, not an agent.

## Per-repo

Global files carry behavior; repo files carry facts about that repo. Repo mode also assesses and
reports selected Matt Pocock skills, project agents, hooks for both harnesses, MCP,
memory, schedules/goals, and worktrees — see `docs/PER-REPO.md`.

## Global skills and plugins

`install.sh` handles the instruction files and agents. Skills and plugins are a separate layer with
two different delivery mechanisms — `npx skills` and the `claude plugin` / `codex plugin`
marketplaces — provisioned by `./skills.sh`, whose manifest is the tier. `docs/SKILLS.md` records
why each entry earned global scope and what was rejected; `validate.sh` fails if the two disagree.

The trap worth knowing: **a skill exists only where its harness looks for it.** The `skills` CLI
picks the store layout itself and has changed it, so verify the file the harness reads —
`ls ~/.claude/skills/*/SKILL.md`, or `./skills.sh --check` for the whole tier — and always pass
`--agent claude-code codex` explicitly rather than trusting the remembered default. An absent
`~/.agents/` is normal for a single-agent install, not a fault.

## Why this repo isn't in `~/.agents/`

`~/.agents/` is the store that `npx skills` manages, with its own `.skill-lock.json`. Authored
source that you want git history for does not belong in a directory another tool installs into,
updates, and prunes. Keep this checkout anywhere outside that managed store and symlink the skill
into both harnesses — the same edit-in-place ergonomics as before, without sharing a directory
with a package manager.
