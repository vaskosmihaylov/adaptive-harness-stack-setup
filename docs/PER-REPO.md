# Per-repository setup

The global harness carries personal behavior and blast-radius defaults. A repository carries
facts and optional tooling specific to that repository. Repository mode must inspect first and
install only what the repository can justify.

## Baseline instruction files

Create `CLAUDE.md` and `AGENTS.md` with the same repository facts. Keep only information the
agent cannot reliably infer:

- environment-to-context/workspace/account mappings;
- exact validate, test, plan/diff, and deploy commands;
- non-obvious destructive boundaries, ordering constraints, and resources that must not be
  recreated;
- repository-specific conventions and done criteria.

Use nested instruction files only when a monorepo subtree has materially different commands or
constraints. Never copy the global guidelines into a repository.

## Matt Pocock skills

Treat [mattpocock/skills](https://github.com/mattpocock/skills) as a fast-moving upstream. Fetch
its current catalog during every repository setup; do not rely on a hard-coded list and do not
install the full catalog by default.

The small repo-agnostic tier is already installed globally — `diagnosing-bugs`, `handoff`,
`resolving-merge-conflicts`, and `wizard`. See `docs/SKILLS.md`. **Do not reinstall those per
repository.**

What remains for repository mode is the repository-configured half:

```bash
npx skills@latest add mattpocock/skills --skill <names...> --agent claude-code codex
npx skills update
```

Tracker workflow candidates are `setup-matt-pocock-skills`, `to-spec`, `to-tickets`, `implement`,
`triage`, and `wayfinder`; include and run setup before selecting those. `code-review` and
`grill-with-docs` instead depend on repository standards, specs, and domain-document layout.
Select any of them only when the repository's tracker, test seams, and documentation workflow
support them.

`research` is optional per repo when the user explicitly wants a durable cited Markdown artifact.
Do not install it merely for current dependency docs: web lookup already covers that.
Do not install `grill-me` alone; it delegates to the separate `grilling` skill. Prefer
`grill-with-docs` when the repository benefits from a lasting `CONTEXT.md` or ADR update.

Do not force `tdd`, `codebase-design`, `improve-codebase-architecture`, `prototype`, or
`domain-modeling` onto Terraform, Helm, Kubernetes, Ansible, or Puppet repositories — they all
assume application code with test seams.

The Claude managed plugin is a valid alternative, but it installs the complete read-only bundle,
auto-updates, and is Claude-only. Do not install both the plugin and editable repository copies.

## Security skills

`trailofbits/skills` is a plugin marketplace, already added to both harnesses, with `gh-cli`,
`git-cleanup`, and `insecure-defaults` installed globally (`docs/SKILLS.md`). Two of its plugins
are repository decisions:

- **`static-analysis`** (the `semgrep` skill) — when a Semgrep scan is wanted. Semgrep covers
  HCL/Terraform, Dockerfile, and YAML, so it is the one general-purpose static analyser that
  reaches this toolchain. Requires the `semgrep` binary. **Pin third-party ruleset revisions** —
  Trail of Bits, 0xdea, and Decurity rules are executable patterns fetched over the network, and
  an unpinned audit is neither reproducible nor reviewed. Keep `--metrics=off`.
- **`agentic-actions-auditor`** — only when the repository's workflows invoke Claude Code Action,
  Gemini CLI, OpenAI Codex, or GitHub AI Inference. It audits AI agents in CI (prompt injection
  via `pull_request_target`/`issue_comment`, env-var intermediaries, wildcard allowlists), not
  general Actions security.

`insecure-defaults` runs on demand as `/insecure-defaults:audit <path>`. Never wire it to a hook —
one run fans out to a recon agent, six parallel sweeps, N Opus verifiers, and a report agent. Its
value over `checkov`/`tfsec`/`trivy` is reachability, not pattern coverage.

Note `trailofbits/skills` is CC-BY-SA-4.0. Using the plugins is fine; copying or adapting their
skill text into a company repository makes the derivative share-alike.

## Repository agents

Default: none. The main models already cover engineering roles, and Matt Pocock's workflow skills
provide orchestration when selected. A permanent agent earns a repository file only when the same
bounded job recurs and benefits from a different model, tool set, permission boundary, or context
window.

Good evidence-backed examples are a read-only domain investigator for a very large monorepo or a
log extractor for a repository with unusually large proprietary logs. Do not create generic
planner, implementer, reviewer, Terraform, Kubernetes, or “engineering division” roles.

When justified, create equivalent definitions in `.claude/agents/` and `.codex/agents/`, pin the
model and effort, minimize tools, and make read-only the default. For parallel writers, require
file ownership and worktree isolation. Project agents override the global utilities only when the
repository has a measured reason.

## Hooks

Use a hook only for behavior that must be deterministic. Configure both harnesses where the same
policy applies:

- Claude Code: `.claude/settings.json`
- Codex: `.codex/hooks.json` or `.codex/config.toml`

Strong candidates are blocking writes to state/secret paths, formatting a changed file, or running
a fast repository-native validation command at stop. Do not add a generic verification hook: the
check must exist in the repository and be cheap enough to run at that lifecycle point. Codex
project hooks require project trust and explicit hook review.

## MCP

Prefer native CLIs: `git`, `gh`, `kubectl`, `helm`, `terraform`, `tofu`, cloud CLIs, and `argocd`
are context-efficient and already expose identity and dry-run controls.

Recommend a project-scoped MCP only when a recurring live-data capability has no adequate CLI or
the MCP is materially better. Document its credential scope, read/write surface, enabled tools,
fallback, and owner. Use `.mcp.json` for Claude and `.codex/config.toml` for Codex. Never put
secrets directly in either file.

## Memory

`AGENTS.md`, `CLAUDE.md`, checked-in docs, ADRs, and the issue tracker are the source of truth.
They are enough for most repositories.

Offer additional memory only for a demonstrated cross-session need:

- Claude project memory on a selected custom agent when that agent benefits from learned project
  patterns;
- Codex local memories as an optional personal recall layer, never the only copy of a rule or
  decision;
- a concise `CONTEXT.md` only when the repository has domain vocabulary that code and existing
  docs do not explain.

Never store credentials, tokens, or production data in memory.

## Scheduling and goals

Recommend concrete tasks only when the repository has a stable recurring operation:

- Claude `/loop` for session-scoped polling, `/goal` for continuous work toward a condition,
  Desktop/cloud schedules or CI for durable automation;
- Codex scheduled tasks in ChatGPT desktop/web for recurring local or connected work; Codex CLI
  does not manage schedules;
- repository CI cron for deterministic, team-owned checks.

Examples: babysit a PR, summarize dependency drift weekly, check expiring certificates, or poll a
deployment. Prefer event-driven CI/webhooks over polling when available. Do not create schedules
during setup; offer the prompt, cadence, required access, and stop condition first.

## Worktrees

Recommend worktrees when concurrent write tasks, long-running changes, scheduled edits, or risky
experiments would otherwise collide. Skip them for read-only analysis and normal single-track
work. Check setup requirements, ignored local files, disk cost, and cleanup before recommending
them. Never copy secrets through `.worktreeinclude` without explicit approval.

Use `claude --worktree <name>` for Claude Code. Use managed worktrees in the ChatGPT desktop app
for Codex local/scheduled chats; for Codex CLI, use ordinary `git worktree` commands and separate
sessions.

## Required final report

Repository mode ends with two short sections:

1. **Configured** — instruction files, selected skills, agents, hooks, and other files actually
   changed.
2. **Recommended next** — one evidence-backed item or `None` for each of: Matt Pocock skills,
   security skills, repository agents, hooks, MCP, memory, schedules/goals, and
   worktrees. Include exact commands or target files, but do not install optional components
   without the user's approval.

State what was inspected and what could not be determined. Do not emit a generic catalog.
