---
name: adaptive-harness-stack-setup
description: Maintain the global Claude Code / Codex CLI harness, or set up a repository to use it. Retune re-checks the lean global guidance and utility-agent model tiers against current vendor docs. Repo mode creates minimal CLAUDE.md/AGENTS.md files, manages justified project agents, and assesses Matt Pocock skills, hooks, MCP, memory, schedules/goals, and worktrees.
---

# Adaptive harness stack setup

Resolve the harness repository as the parent of this `skill/` directory. Never assume a particular
username, home directory, or checkout path.

```
src/          core.md + per-harness header/footer  ← the only files you edit
dist/         generated CLAUDE.md and AGENTS.md    ← never edit
agents/       cheap-tier subagent definitions (claude/*.md, codex/*.toml)
settings/     Claude permission allowlist
templates/    per-repo CLAUDE.md / AGENTS.md starter
docs/         SOURCES.md, PER-REPO.md, TOKENS.md
backups/      timestamped copies of everything replaced
```

## Pick the mode

Ask which is wanted if the request is ambiguous. Don't run both.

- **retune** — the global harness. Touches `src/` and `~/.claude` / `~/.codex`.
- **repo** — the current repository. Touches this repo only, never the global files.

---

## Mode: retune

The governing principle for every line in `src/core.md`:

> **Would removing this cause a mistake the model wouldn't otherwise make?** If not, cut it.

Anthropic's own guidance says current models need *less* scaffolding, not more. Verification
steps, self-check loops, agent rosters, and TDD/security manifestos are actively
counterproductive on Opus 5. `docs/SOURCES.md` carries the citations.

1. Read `docs/SOURCES.md` — the rule-by-rule justification, the cut list, and the changelog.
2. Re-fetch the model-specific prompting guides listed there. Look for what *changed*: new
   default verbosity, new delegation tendencies, instructions the vendor now says to remove.
3. Go section by section through `src/core.md`: keep / trim / cut. Bias toward cutting.
4. Re-check the cheap tier in `agents/` — model names go stale fastest. Verify the ids against
   current official docs and the installed CLIs before writing them (`docs/TOKENS.md` explains
   the tiering). Prefer overriding native exploration roles over adding synonymous agents.
5. Run `./skills.sh --check` for the documented tier, then audit what it cannot see: both MCP
   lists, and any skill or plugin installed outside the manifest. Confirm the upstream names still
   exist (`npx skills add <repo> --list`, the marketplace manifest) before concluding a name is
   fine. On a new machine, offer `./skills.sh` and MCP authentication; never install silently.
6. Edit authored sources, agents, and their rationale docs — a change to the tier means editing the
   `skills.sh` manifest and `docs/SKILLS.md` together. Then run `./validate.sh`,
   `./install.sh --dry-run`, and `./install.sh` — adding `--claude` on a machine where Codex is
   absent or unconfigured.
7. Record what changed and why in the `docs/SOURCES.md` changelog.

Report the net line delta. If the file grew, justify it.

---

## Mode: repo

Set up the current repository. Follow `docs/PER-REPO.md`. This mode may create local repository
files, but it never edits `~/.claude` or `~/.codex`.

Write harness-specific config only for harnesses installed on this machine — check `command -v
claude` and `command -v codex` (a Codex binary with no `~/.codex/config.toml` is an unconfigured
install, so treat it as absent). `CLAUDE.md` and `AGENTS.md` are the exception: always write both.
`AGENTS.md` is the cross-tool convention that other agents read, so it earns its place in a
shared repo whether or not Codex runs here.

1. Resolve the target from the current working directory (`git rev-parse --show-toplevel` when it
   is a Git repository, otherwise the explicit working directory). Refuse the filesystem root,
   the home directory itself, harness configuration directories, and targets the current user
   cannot write. Do not assume fixed `Work` or `Personal` parent directories. Read the repository
   first: build and dependency files, CI, existing instructions/docs, Git status, directory
   layout, and exact native validation commands. Preserve unrelated user changes.
2. Back up or edit existing instruction files in place; never overwrite repository guidance
   blindly. For a new repo, copy `templates/PROJECT.md` to `CLAUDE.md`, fill only what the agent
   cannot infer by reading the repo, delete every section left empty, then copy the repository
   facts to `AGENTS.md`.
   The two highest-value things are almost always: **which context/workspace/account maps to
   which environment**, and **the exact validate/plan/apply invocations**.
3. Fetch the current `mattpocock/skills` catalog. Do not reinstall the global tier per repo.
   Recommend repository-configured skills only when their tracker or documentation workflow is
   useful; include `setup-matt-pocock-skills` when a selected skill needs its configuration.
   Never install the full catalog by default or both the Claude plugin and editable copies. Then
   assess the two per-repo security plugins: `static-analysis`/`semgrep` (not installed at any
   scope — recommend it only for the orchestration it adds over the plain binary, install with
   `--scope project`, pin third-party ruleset revisions, and point third-party configs at rule
   subdirectories rather than a clone root) and `agentic-actions-auditor` (only if workflows
   invoke AI agents). Behind a TLS interceptor, Semgrep registry rulesets cannot be fetched by the
   host binary at all; read `docs/SKILLS.md` rather than debugging TLS in repo mode.
4. Assess repository agents. Default to none. Create definitions only for a recurring bounded job
   that needs a distinct model, tool/permission boundary, or context window — in `.claude/agents/`
   and `.codex/agents/`, per installed harness. Pin model and effort; prefer read-only. Do not
   recreate generic planner, implementer, reviewer, or technology-specialist roles.
5. Assess deterministic hooks for each installed harness (`.claude/settings.json`; for Codex,
   `.codex/hooks.json` or `.codex/config.toml`). Add only repository-native checks or protections
   that must run every time; do not add generic verification scaffolding.
6. Assess project-scoped MCP. Prefer native CLIs. Never write credentials or modify
   the user's global Codex configuration in repo mode.
7. Assess memory, schedules/goals, and worktrees. Checked-in instructions/docs are the default
   memory. Offer schedules with a prompt, cadence, access, and stop condition; do not create them
   during setup. Offer worktrees only for concurrent or long-running writes and explain setup,
   ignored-file, disk, and cleanup implications.
8. Validate every created JSON/TOML/YAML/frontmatter file and run the repository's safe native
   checks when applicable. Never weaken an existing test.
9. End with exactly two concise sections:
   - **Configured**: files and components actually changed.
   - **Recommended next**: one evidence-backed recommendation or `None` for each of Matt Pocock
     skills, security skills, repository agents, hooks, MCP, memory, schedules/goals,
     and worktrees.
     Include exact commands/paths. Ask before network installs, MCP authentication, or creating
     schedules; evidence-backed local instruction, agent, hook, and config files are in scope.

Do not copy the global guidelines into the repo file — they already load.

---

## Rules

- Never edit `dist/` — `build.sh` overwrites it.
- Never rewrite `~/.codex/config.toml`; it holds ~50 project trust levels. Report drift, don't fix it.
- Global files carry *behavior*. Repo files carry *facts about that repo*. Don't mix them.
- Verify model ids against the installed CLI before writing them into `agents/`. They change often.
- In `agents/claude/`, pin the tier alias (`haiku`, `sonnet`, `opus`), not a dated id. A machine
  routing through a gateway resolves aliases via `ANTHROPIC_DEFAULT_*_MODEL` in `settings.json`;
  a hard-coded vendor id bypasses that mapping and fails.
- Treat network installs, MCP authentication, and schedules as offers until the user approves them.
