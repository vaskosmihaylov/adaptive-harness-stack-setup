<!--
Per-repo template. Copy to CLAUDE.md (Claude Code) and/or AGENTS.md (Codex) at the repo root.

Rule for every line you keep: "would removing this cause a mistake?" If not, cut it.
Do NOT restate what the agent can learn by reading the repo, and do NOT restate the global
guidelines in ~/.claude/CLAUDE.md and ~/.codex/AGENTS.md — those already load.

Delete every section you don't fill in. An empty heading costs context and teaches nothing.
-->

# <repo name>

<one sentence: what this deploys/manages, and for whom>

## Environments

| Env | Context / workspace / account | Notes |
|-----|-------------------------------|-------|
| dev | | |
| prod | | **production — confirm before any mutation** |

## Commands

<!-- Only ones that can't be guessed from the repo. Include the exact invocation. -->

- Validate: `…`
- Plan/diff: `…`
- Test: `…`
- Lint/format: `…`
- Apply/deploy: `…`  <!-- and who is allowed to run it -->

## Gotchas

<!-- Non-obvious behavior that has burned someone. Required env vars, ordering constraints,
     resources that must never be recreated, state locking, drift that is expected. -->

-

## Conventions

<!-- Only where this repo differs from the obvious default. -->

-
