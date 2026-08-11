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

## Global utility tier

Only two cross-repository utilities are installed:

| Job | Claude Code | Codex |
|---|---|---|
| built-in exploration override | `Explore`, Haiku, low effort | `explorer`, `gpt-5.6-terra`, low effort |
| high-volume log extraction | `log-digger`, Haiku, low effort | `log-digger`, `gpt-5.6-luna`, low effort |

The explorer names intentionally override the harness built-ins so routine exploration does not
inherit Opus or Sol. Terra is the documented efficient read-heavy Codex tier; Luna is reserved for
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

Add another persistent agent only if it needs a distinct model, tool/permission boundary, or
separate context window and the job recurs. Otherwise use a prompt or skill.
