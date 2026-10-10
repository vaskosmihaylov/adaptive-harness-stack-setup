# Token usage and orchestration

The largest saving is avoiding unnecessary work. Model tiering helps only after the task genuinely
benefits from separate context or parallel execution.

## Right-size first

- Small, clear work: main agent only; no plan artifact and no subagent.
- Unclear approach: plan on the main model.
- Wide, noisy investigation: one read-only explorer.
- High-volume logs or plan output: one log extractor.
- Several independent, substantial tracks: bounded parallel agents, with the main model retaining
  planning and final judgment.

Subagents consume additional tokens even when they reduce wall-clock time and protect the main
context. Do not use a second agent only to repeat the first agent's verification.

## Which model does what

| Tier | Job |
|---|---|
| Opus (main model) | planning, judgment, review, and every decision that lands in a file |
| Haiku | the utilities below — wide search, high-volume log extraction, and doc distillation |
| Sonnet | `model: sonnet` on a one-off `general-purpose` agent when a delegated job outgrows Haiku but still needs no judgment |

Sonnet gets no installed agent on purpose. It is a model override on an existing roster entry, not
another definition every session has to read.

## Global utility tier

Only these cross-repository utilities are installed:

| Job | Claude Code | Codex |
|---|---|---|
| built-in exploration override | `Explore`, Haiku, low effort | `explorer`, `gpt-5.6-terra`, low effort |
| high-volume log extraction | `log-digger`, Haiku, low effort | `log-digger`, `gpt-5.6-luna`, low effort |
| dependency doc distillation | `docs-lookup`, Haiku, low effort | none |

The explorer names intentionally override the harness built-ins so routine exploration does not
inherit Opus or Sol. `docs-lookup` (added 2026-08-22) keeps fetched documentation pages out of
the main context, which the Documentation freshness rule otherwise pulls in on every dependency
question. It is Claude-only for now; no Codex equivalent has been written or tested. Terra is the documented efficient read-heavy Codex tier; Luna is reserved for
narrow, repeatable, high-volume extraction. Both utilities are read-only.

No global planner, implementer, reviewer, language specialist, DevOps division, or orchestrator is
installed. Current main models already perform those roles, while repository skills and agents can
add a workflow when the repository supplies evidence for it.

## Why not install `codex_workflow` globally

Its useful ideas are retained: a light default, expensive-model planning, compact work packages,
cheap bounded workers, and durable state for genuinely long work. Its fixed light/medium/heavy
routes, executor/tester roster, repair loops, and mandatory project-state documents are not global
defaults. They duplicate current native orchestration and add context to every repository.

For a very large implementation, express the useful subset in the repository's selected workflow
skill: define independent work packages, cap concurrency, use cheaper workers only where quality
holds, and keep durable state in the existing issue/spec system.

## Defaults

- Main interactive reasoning: `medium` is the balanced starting point; raise it only for measured
  hard reasoning.
- Claude Opus 5: lower effort controls thinking cost, not visible response length.
- Codex GPT-5.6: lean prompts and a single compact autonomy/approval policy outperform repeated
  instructions.
- Cap concurrency. Four workers is an upper bound, not a target.

`settings/claude-settings.json` makes those last two deterministic rather than advisory, because
Opus 5 delegates more readily than earlier models and prose alone does not bound a tree of agents:

| Key | Set | Default | Effect |
|---|---|---|---|
| `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` | `1` | `3` | subagents cannot spawn subagents; the main agent still delegates normally |
| `CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` | `4` | `20` | a fifth concurrent spawn returns `Concurrent subagent limit reached` |

Both need Claude Code ≥ 2.1.219. Depth `1` is right for a flat utility roster: none of the utilities
has any reason to fan out further.

`BASH_MAX_OUTPUT_LENGTH` caps the same hazard harder, and is deliberately **not** set. It truncates
silently, so a lowered cap trades context growth for the chance of acting on a half-read
`terraform plan`. Set it per-session if a specific command is the problem.

Add another persistent agent only if it needs a distinct model, tool/permission boundary, or
separate context window and the job recurs. Otherwise use a prompt or skill.
